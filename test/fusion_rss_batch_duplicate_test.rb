# frozen_string_literal: true

require_relative 'test_helper'

class FusionRssBatchDuplicateTest < Minitest::Test
  def make_entry(title:, url:, published_at:, feed_name: 'f')
    FusionRss::FeedEntry.new title: title, url: url, published_at: published_at, feed_name: feed_name
  end

  def make_filter
    obj = Object.new
    obj.define_singleton_method(:match?) { |_entry| false }
    obj.define_singleton_method(:blacklisted_count) { 0 }
    obj.define_singleton_method(:unstable_count) { 0 }
    obj
  end

  def test_adding_duplicates_within_same_batch
    fusion = FusionRss.new make_filter, 10

    now = Time.now
    fusion.send :add,
                make_entry(title: 'first', url: 'https://dup.example/', published_at: now - 5),
                make_entry(title: 'second', url: 'https://dup.example/', published_at: now),
                make_entry(title: 'third', url: 'https://other.example/', published_at: now + 5)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 1, stats.items_skipped_duplicate
    assert_equal 2, stats.items_output
    rss = fusion.send :to_rss
    assert_includes rss, '<title>third</title>'
    assert_includes rss, '<title>first</title>'
  end
end
