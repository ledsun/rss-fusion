# frozen_string_literal: true

# Item represents a merged feed entry
Item = Data.define(:title, :url, :published_at, :feed_name)

class MergedItems
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
    items = @items.sort_by { |item| item.published_at || Time.at(0) }
                  .reverse
                  .first(@max_items)
    stats.finalize(output: items.length, blacklisted: @blacklisted_count, duplicate: @duplicate_count)
    items
  end
end