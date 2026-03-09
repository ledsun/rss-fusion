# frozen_string_literal: true

class FusionRss
  # FeedEntry represents a single merged RSS item.
  class FeedEntry
    attr_reader :title, :url, :published_at, :feed_name, :summary, :categories

    def initialize(title, url, published_at, feed_name, attributes = {})
      @title = title
      @url = url
      @published_at = published_at
      @feed_name = feed_name
      @summary = attributes.fetch :summary, nil
      @categories = attributes.fetch :categories, []
    end

    def to_rss_entry(maker) = maker.items.new_item { populate_entry it }

    def populate_entry(entry)
      entry.title = title
      entry.link = url
      entry.guid.content = url
      entry.guid.isPermaLink = true
      entry.pubDate = published_at
    end
  end
end
