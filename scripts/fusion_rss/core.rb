# frozen_string_literal: true

require 'rss'
require 'fileutils'

# FusionRss collects entries and builds the final merged RSS payload.
class FusionRss
  def initialize(blacklist, max_feeds, github_release_filter: nil)
    @blacklist               = blacklist
    @max_feeds               = max_feeds
    @github_release_filter   = github_release_filter
    @feeds                   = []
    @blacklisted_count       = 0
    @duplicate_count         = 0
    @unstable_count          = 0
  end

  def add(feed_entry)
    if @blacklist.match?(feed_entry.url)
      @blacklisted_count += 1
    elsif @github_release_filter&.unstable?(feed_entry.url)
      @unstable_count += 1
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
    stats.finalize(output: @finalized_feeds.length, blacklisted: @blacklisted_count,
                   duplicate: @duplicate_count, unstable: @unstable_count)
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
