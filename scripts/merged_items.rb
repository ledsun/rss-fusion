# frozen_string_literal: true

class MergedItems
  def initialize(blacklist_rules:, max_items:)
    @blacklist_rules = blacklist_rules
    @max_items       = max_items
    @seen_urls       = {}
    @items           = []
  end

  # Returns :added, :blacklisted, or :duplicate
  def add(item)
    if @blacklist_rules.any? { |prefix| item.url.start_with?(prefix) }
      :blacklisted
    elsif @seen_urls[item.url]
      :duplicate
    else
      @seen_urls[item.url] = true
      @items << item
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