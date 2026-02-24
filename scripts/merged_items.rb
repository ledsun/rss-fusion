# frozen_string_literal: true

# Item represents a merged feed entry
Item = Data.define(:title, :url, :published_at, :feed_name)

class MergedItems
  def initialize(blacklist_rules:, max_items:)
    @blacklist_rules = blacklist_rules
    @max_items       = max_items
    @seen_urls       = {}
    @items           = []
  end

  # Returns :added, :blacklisted, or :duplicate
  def add(title:, url:, published_at:, feed_name:)
    if @blacklist_rules.any? { |prefix| url.start_with?(prefix) }
      :blacklisted
    elsif @seen_urls[url]
      :duplicate
    else
      @seen_urls[url] = true
      @items << Item.new(title: title, url: url, published_at: published_at, feed_name: feed_name)
      :added
    end
  end

  def finalized
    @items
      .sort_by { |item| item.published_at || Time.at(0) }
      .reverse
      .first(@max_items)
  end
end