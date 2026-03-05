# frozen_string_literal: true

require 'rss'
require 'fileutils'

# FusionRss collects entries and builds the final merged RSS payload.
class FusionRss
  def initialize(filter, max_feeds)
    @filter    = filter
    @max_feeds = max_feeds
    @feeds     = []
  end

  def add(*feed_entries)
    @feeds.concat(feed_entries.reject { @filter.match?(it) })
  end

  def finalize(stats)
    unique_feeds = @feeds.uniq(&:url)
    duplicate = @feeds.length - unique_feeds.length

    sorted_feeds = unique_feeds.sort_by { it.published_at || Time.at(0) }.reverse
    @finalized_feeds = sorted_feeds.first(@max_feeds)
    stats.finalize(output: @finalized_feeds.length, blacklisted: @filter.blacklisted_count,
                   duplicate:, unstable: @filter.unstable_count)
    @finalized_feeds
  end

  def write(path)
    tmp_path = "#{path}.tmp"
    FileUtils.mkdir_p(File.dirname(path))
    File.write(tmp_path, to_rss)
    File.rename(tmp_path, path)
  end

  private

  def to_rss
    RSS::Maker.make('2.0') do
      maker = it
      maker.channel.title = 'RSS Fusion'
      maker.channel.description = 'Merged RSS feed generated from multiple sources'
      maker.channel.link = 'https://example.invalid/merged.xml'
      maker.channel.updated = Time.now

      @finalized_feeds.each { it.to_rss_entry(maker) }
    end.to_s
  end
end
