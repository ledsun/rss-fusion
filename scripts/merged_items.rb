# frozen_string_literal: true

require "rss"

# Item represents a merged feed entry
Item = Data.define(:title, :url, :published_at, :feed_name)

class FusionRss
  def initialize(blacklist_rules:, max_items:)
    @blacklist_rules    = blacklist_rules
    @max_items          = max_items
    @seen_urls          = {}
    @items              = []
    @blacklisted_count  = 0
    @duplicate_count    = 0
  end

  def add(title:, url:, published_at:, feed_name:)
    if @blacklist_rules.any? { |prefix| url.start_with?(prefix) }
      @blacklisted_count += 1
    elsif @seen_urls[url]
      @duplicate_count += 1
    else
      @seen_urls[url] = true
      @items << Item.new(title: title, url: url, published_at: published_at, feed_name: feed_name)
    end
  end

  def finalized(stats)
    @finalized_items = @items.sort_by { |item| item.published_at || Time.at(0) }
                             .reverse
                             .first(@max_items)
    stats.finalize(output: @finalized_items.length, blacklisted: @blacklisted_count, duplicate: @duplicate_count)
    @finalized_items
  end

  def to_rss
    RSS::Maker.make("2.0") do |maker|
      maker.channel.title = "RSS Fusion"
      maker.channel.description = "Merged RSS feed generated from multiple sources"
      maker.channel.link = "https://example.invalid/merged.xml"
      maker.channel.updated = Time.now

      @finalized_items.each do |item|
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
end

# Backward compatibility: keep the old constant name for callers that still reference it
MergedItems = FusionRss