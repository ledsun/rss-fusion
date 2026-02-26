# frozen_string_literal: true

class FusionRss
  # FeedEntry represents a single merged RSS item.
  class FeedEntry
    attr_reader :title, :url, :published_at, :feed_name

    def initialize(title:, url:, published_at:, feed_name:)
      @title = title
      @url = url
      @published_at = published_at
      @feed_name = feed_name
    end

    def to_rss_entry(maker)
      maker.items.new_item do |entry|
        populate_entry(entry)
      end
    end

    def populate_entry(entry)
      entry.title = title
      entry.link = url
      entry.guid.content = url
      entry.guid.isPermaLink = true
      entry.pubDate = published_at
    end
  end
end
