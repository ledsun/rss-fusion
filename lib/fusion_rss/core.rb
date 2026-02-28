# frozen_string_literal: true

require 'rss'
require 'fileutils'

# FusionRss collects entries and builds the final merged RSS payload.
class FusionRss
  def initialize(filter, max_feeds)
    @filter          = filter
    @max_feeds       = max_feeds
    @feeds           = []
    @duplicate_count = 0
  end

  def add(feed_entry)
    if @filter.match?(feed_entry.url)
      # filtered (counted inside Filter)
    elsif @feeds.any? { |it| it.url == feed_entry.url }
      @duplicate_count += 1
    else
      @feeds << feed_entry
    end
  end

  def finalize(stats)
    @finalized_feeds = @feeds.sort_by { |feed| feed.published_at || Time.at(0) }
                             .reverse
                             .first(@max_feeds)
    stats.finalize(output: @finalized_feeds.length, blacklisted: @filter.blacklisted_count,
                   duplicate: @duplicate_count, unstable: @filter.unstable_count)
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
    RSS::Maker.make('2.0') do |maker|
      maker.channel.title = 'RSS Fusion'
      maker.channel.description = 'Merged RSS feed generated from multiple sources'
      maker.channel.link = 'https://example.invalid/merged.xml'
      maker.channel.updated = Time.now

      @finalized_feeds.each { |feed| feed.to_rss_entry(maker) }
    end.to_s
  end
end
