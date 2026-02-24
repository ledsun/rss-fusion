#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "net/http"
require "uri"
require "time"
require "fileutils"
require "rss"
require "feedjira"

FEEDS_PATH = "feeds.yml"
BLACKLIST_PATH = "blacklist.txt"
OUTPUT_DIR = "public"
OUTPUT_PATH = File.join(OUTPUT_DIR, "merged.xml")
TMP_OUTPUT_PATH = "#{OUTPUT_PATH}.tmp"
USER_AGENT = "rss-merge-bot/0.1"
OPEN_TIMEOUT = 10
READ_TIMEOUT = 20
MAX_REDIRECTS = 3
MAX_ITEMS = 50

# Item represents a merged feed entry
Item = Data.define(:title, :url, :published_at, :feed_name)

class Stats
  attr_reader :feeds_total, :feeds_succeeded, :feeds_failed,
              :items_fetched, :items_skipped_no_url, :items_skipped_blacklist,
              :items_skipped_duplicate, :items_output

  def initialize(feeds_total:)
    @feeds_total           = feeds_total
    @feeds_succeeded       = 0
    @feeds_failed          = 0
    @items_fetched         = 0
    @items_skipped_no_url  = 0
    @items_skipped_blacklist = 0
    @items_skipped_duplicate = 0
    @items_output          = 0
  end

  def feed_succeeded    = tap { @feeds_succeeded += 1 }
  def feed_failed       = tap { @feeds_failed += 1 }
  def item_fetched      = tap { @items_fetched += 1 }
  def item_skipped_no_url    = tap { @items_skipped_no_url += 1 }
  def item_skipped_blacklist = tap { @items_skipped_blacklist += 1 }
  def item_skipped_duplicate = tap { @items_skipped_duplicate += 1 }
  def finalize(count)   = tap { @items_output = count }

  def summary
    [
      "feeds total=#{feeds_total} success=#{feeds_succeeded} failed=#{feeds_failed}",
      "items fetched=#{items_fetched} skipped_no_url=#{items_skipped_no_url} skipped_blacklist=#{items_skipped_blacklist} skipped_duplicate=#{items_skipped_duplicate} output=#{items_output}"
    ]
  end
end

def log(msg)
  puts "[build_feed] #{msg}"
end

def load_feeds(path)
  data = YAML.load_file(path)
  feeds = data.is_a?(Hash) ? data["feeds"] : nil
  unless feeds.is_a?(Array)
    raise "Invalid feeds.yml: top-level 'feeds' array is required"
  end

  feeds.filter_map do |row|
    unless row.is_a?(Hash)
      log "Skipping invalid feed row: #{row.inspect}"
      next
    end

    name = row["name"].to_s.strip
    url = row["url"].to_s.strip
    if name.empty? || url.empty?
      log "Skipping feed row with missing name/url: #{row.inspect}"
      next
    end

    { name: name, url: url }
  end
end

def load_blacklist(path)
  return [] unless File.exist?(path)

  File.readlines(path, chomp: true).filter_map do |line|
    rule = line.strip
    next if rule.empty? || rule.start_with?("#")

    rule
  end
end

def http_get(url, limit: MAX_REDIRECTS)
  raise "Too many redirects while fetching #{url}" if limit.negative?

  uri = URI.parse(url)
  raise "Unsupported URL scheme for #{url}" unless %w[http https].include?(uri.scheme)

  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = USER_AGENT

  response = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == "https",
    open_timeout: OPEN_TIMEOUT,
    read_timeout: READ_TIMEOUT
  ) do |http|
    http.request(request)
  end

  case response
  when Net::HTTPSuccess
    response.body.to_s
  when Net::HTTPRedirection
    location = response["location"]
    raise "Redirect response without Location for #{url}" if location.to_s.strip.empty?

    redirected = URI.join(url, location).to_s
    http_get(redirected, limit: limit - 1)
  else
    raise "HTTP #{response.code} #{response.message} for #{url}"
  end
end

def feed_entries(parsed_feed)
  entries = parsed_feed.respond_to?(:entries) ? parsed_feed.entries : nil
  entries.is_a?(Array) ? entries : []
end

def extract_url(entry)
  candidates = []
  candidates << entry.url if entry.respond_to?(:url)
  candidates << entry.link if entry.respond_to?(:link)
  candidates << entry.links&.first if entry.respond_to?(:links)

  candidates.map { |v| v.to_s.strip }.find { |v| !v.empty? }
end

def extract_published_at(entry, fallback_time)
  value =
    if entry.respond_to?(:published) && entry.published
      entry.published
    elsif entry.respond_to?(:updated) && entry.updated
      entry.updated
    elsif entry.respond_to?(:last_modified) && entry.last_modified
      entry.last_modified
    elsif entry.respond_to?(:published_at) && entry.published_at
      entry.published_at
    end

  return fallback_time if value.nil?
  return value if value.is_a?(Time)

  Time.parse(value.to_s)
rescue StandardError
  fallback_time
end

def prefixed_title(feed_name, original_title)
  base = original_title.to_s.strip
  base = "(no title)" if base.empty?
  "[#{feed_name}] #{base}"
end

def build_rss(items)
  RSS::Maker.make("2.0") do |maker|
    maker.channel.title = "RSS Fusion"
    maker.channel.description = "Merged RSS feed generated from multiple sources"
    maker.channel.link = "https://example.invalid/merged.xml"
    maker.channel.updated = Time.now

    items.each do |item|
      maker.items.new_item do |entry|
        entry.title = item.title
        entry.link = item.url
        entry.guid.content = item.url
        entry.guid.isPermaLink = true
        entry.pubDate = item.published_at
      end
    end
  end.to_s
end

def write_atomically(path, tmp_path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(tmp_path, content)
  File.rename(tmp_path, path)
end

def main
  feeds = load_feeds(FEEDS_PATH)
  blacklist_rules = load_blacklist(BLACKLIST_PATH)
  stats = Stats.new(feeds_total: feeds.length)

  log "Loaded #{feeds.length} feeds"
  log "Loaded #{blacklist_rules.length} blacklist rules"

  seen_urls = {}
  merged_items = []

  feeds.each do |feed|
    fetched_at = Time.now
    body = http_get(feed[:url])
    parsed = Feedjira.parse(body)
    entries = feed_entries(parsed)
    stats.feed_succeeded

    log "Fetched #{feed[:name]} (#{feed[:url]}) entries=#{entries.length}"

    entries.each do |entry|
      stats.item_fetched
      url = extract_url(entry)
      if url.to_s.empty?
        stats.item_skipped_no_url
        next
      end

      if blacklist_rules.any? { |prefix| url.start_with?(prefix) }
        stats.item_skipped_blacklist
        next
      end

      if seen_urls[url]
        stats.item_skipped_duplicate
        next
      end
      seen_urls[url] = true

      merged_items << Item.new(
        prefixed_title(feed[:name], entry.respond_to?(:title) ? entry.title : nil),
        url,
        extract_published_at(entry, fetched_at),
        feed[:name]
      )
    end
  rescue StandardError => e
    stats.feed_failed
    log "Feed fetch/parse failed: #{feed[:name]} #{feed[:url]} (#{e.class}: #{e.message})"
  end

  merged_items.sort_by! { |item| item.published_at || Time.at(0) }
  merged_items.reverse!
  merged_items = merged_items.first(MAX_ITEMS)
  stats.finalize(merged_items.length)

  content = build_rss(merged_items)
  write_atomically(OUTPUT_PATH, TMP_OUTPUT_PATH, content)

  stats.summary.each { |line| log "Summary #{line}" }
  log "Wrote #{OUTPUT_PATH}"
end

main
