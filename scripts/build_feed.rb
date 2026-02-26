#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'fileutils'

require 'feedjira'

FEEDS_PATH = 'feeds.yml'
BLACKLIST_PATH = 'blacklist.txt'
OUTPUT_DIR = 'public'
OUTPUT_PATH = File.join(OUTPUT_DIR, 'merged.xml')
TMP_OUTPUT_PATH = "#{OUTPUT_PATH}.tmp".freeze

MAX_ITEMS = 50

require_relative 'stats'
require_relative 'fusion_rss'
require_relative 'loader'

def log(msg)
  puts "[build_feed] #{msg}"
end

def load_blacklist(path)
  return [] unless File.exist?(path)

  File.readlines(path, chomp: true).filter_map do |line|
    rule = line.strip
    next if rule.empty? || rule.start_with?('#')

    rule
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
  base = '(no title)' if base.empty?
  "[#{feed_name}] #{base}"
end

def write_atomically(path, tmp_path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(tmp_path, content)
  File.rename(tmp_path, path)
end

def main
  loader = Loader.new(FEEDS_PATH)
  blacklist_rules = load_blacklist(BLACKLIST_PATH)
  stats = Stats.new(feeds_total: loader.length)

  log "Loaded #{loader.length} feeds"
  log "Loaded #{blacklist_rules.length} blacklist rules"

  merged_items = FusionRss.new(blacklist_rules: blacklist_rules, max_feeds: MAX_ITEMS)

  loader.each do |subscribe_rss|
    fetched_at = Time.now
    body = subscribe_rss.http_get
    parsed = Feedjira.parse(body)
    entries = feed_entries(parsed)
    stats.feed_succeeded

    log "Fetched #{subscribe_rss.name} (#{subscribe_rss.url}) entries=#{entries.length}"

    entries.each do |entry|
      stats.item_fetched
      url = extract_url(entry)
      if url.to_s.empty?
        stats.item_skipped_no_url
        next
      end

      merged_items.add(
        title: prefixed_title(subscribe_rss.name, entry.respond_to?(:title) ? entry.title : nil),
        url: url,
        published_at: extract_published_at(entry, fetched_at),
        feed_name: subscribe_rss.name
      )
    end
  rescue StandardError => e
    stats.feed_failed
    log "Feed fetch/parse failed: #{subscribe_rss.name} #{subscribe_rss.url} (#{e.class}: #{e.message})"
  end

  merged_items.finalized(stats)

  content = merged_items.to_rss
  write_atomically(OUTPUT_PATH, TMP_OUTPUT_PATH, content)

  stats.summary.each { |line| log "Summary #{line}" }
  log "Wrote #{OUTPUT_PATH}"
rescue Loader::ConfigFormatError => e
  log "Feed config load failed: #{FEEDS_PATH} (#{e.class}: #{e.message})"
  raise
end

main
