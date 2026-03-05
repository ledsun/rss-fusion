# frozen_string_literal: true

require 'rss'
require 'fileutils'

# FusionRss collects entries and builds the final merged RSS payload.
class FusionRss
  def initialize(max_feeds, blacklist_path)
    @max_feeds = max_feeds
    @feeds     = []
    @filter    = build_filter blacklist_path
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

    process_entries entries, stats
  rescue StandardError => e
    stats.feed_failed
    log "Feed fetch/parse failed: #{feed_source.name} #{feed_source.url} (#{e.class}: #{e.message})"
  end

  def process_entries(entries, stats)
    valid, skipped = entries.partition { !it.url_blank? }

    stats.item_fetched entries.size
    stats.item_skipped_no_url skipped.size

    add(*valid.map(&:to_fusion_entry))
  end

  def add(*feed_entries)
    @feeds.concat(feed_entries.reject { @filter.match?(it) })
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
      maker.channel.title = 'RSS Fusion'
      maker.channel.description = 'Merged RSS feed generated from multiple sources'
      maker.channel.link = 'https://example.invalid/merged.xml'
      maker.channel.updated = Time.now

      @finalized_feeds.each { it.to_rss_entry maker }
    end.to_s
  end

  def log(msg) = puts "[rss_fusion] #{msg}"
end
