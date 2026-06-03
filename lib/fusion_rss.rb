# frozen_string_literal: true

require 'rss'
require 'fileutils'

# FusionRss collects entries and builds the final merged RSS payload.
class FusionRss
  def initialize(max_feeds, blacklist_path, title = 'RSS Fusion', description = nil)
    @max_feeds    = max_feeds
    @feeds        = []
    @filter       = build_filter blacklist_path
    @title        = title
    @description  = description || 'Merged RSS feed generated from multiple sources'
  end

  def process(feed_catalog)
    stats = Stats.new feed_catalog.length

    feed_catalog.sources.each { fetch_from it, stats }

    finalize stats
    stats
  end

  def write_to(path)
    tmp_path = "#{path}.tmp"
    FileUtils.mkdir_p File.dirname(path)
    File.write tmp_path, to_rss
    File.rename tmp_path, path
  end

  private

  def build_filter(blacklist_path)
    blacklist = Filter::BlackList.read_from blacklist_path
    log "Loaded #{blacklist.length} blacklist rules"
    Filter.new blacklist
  end

  def fetch_from(feed_source, stats)
    entries = feed_source.fetch_entries
    stats.feed_succeeded
    log "Fetched #{feed_source.name} (#{feed_source.url}) entries=#{entries.size}"

    ingest entries, stats
  rescue StandardError => e
    stats.feed_failed
    log "Feed fetch/parse failed: #{feed_source.name} #{feed_source.url} (#{e.class}: #{e.message})"
  end

  def ingest(entries, stats)
    valid, skipped = entries.partition { !it.url_blank? }

    stats.item_fetched entries.size
    stats.item_skipped_no_url skipped.size

    feed_entries = valid.map(&:to_fusion_entry)
    feed_entries.reject! { @filter.match? it }
    @feeds.concat feed_entries
  end

  def finalize(stats)
    unique_feeds = @feeds.uniq(&:url)
    duplicate = @feeds.length - unique_feeds.length

    sorted_feeds = unique_feeds.sort_by { it.published_at || Time.at(0) }.reverse
    @finalized_feeds = sorted_feeds.first @max_feeds
    stats.finalize output: @finalized_feeds.length, blacklisted: @filter.blacklisted_count,
                   duplicate:, unstable: @filter.unstable_count
    @finalized_feeds
  end

  def to_rss
    RSS::Maker.make('2.0') do |maker|
      maker.channel.title = @title
      maker.channel.description = @description
      maker.channel.link = 'https://ledsun.github.io/rss-fusion/'
      maker.channel.updated = Time.now

      @finalized_feeds.each { it.to_rss_entry maker }
    end.to_s
  end

  def log(msg) = puts "[rss_fusion] #{msg}"
end
