# frozen_string_literal: true

require "minitest/autorun"
require_relative "fusion_rss"
require_relative "stats"

class FusionRssTest < Minitest::Test
  def test_finalize_updates_items_output_and_rss_order
    fusion = FusionRss.new(blacklist_rules: [], max_items: 10)

    now = Time.now
    fusion.add(title: "old", url: "https://a.example/", published_at: now - 60, feed_name: "feedA")
    fusion.add(title: "new", url: "https://b.example/", published_at: now, feed_name: "feedB")

    stats = Stats.new(feeds_total: 1)
    fusion.finalized(stats)

    assert_equal 2, stats.items_output

    rss = fusion.to_rss
    idx_new = rss.index("<title>new</title>")
    idx_old = rss.index("<title>old</title>")

    # newer item should appear before older one
    assert idx_new && idx_old
    assert idx_new < idx_old
  end

  def test_blacklist_and_duplicate_counting
    fusion = FusionRss.new(blacklist_rules: ["https://spam.example/"], max_items: 10)

    now = Time.now
    # added item
    fusion.add(title: "ok", url: "https://good.example/1", published_at: now - 30, feed_name: "f")
    # duplicate of the first
    fusion.add(title: "dup", url: "https://good.example/1", published_at: now - 20, feed_name: "f")
    # blacklisted
    fusion.add(title: "spam", url: "https://spam.example/1", published_at: now - 10, feed_name: "f")

    stats = Stats.new(feeds_total: 1)
    fusion.finalized(stats)

    assert_equal 1, stats.items_skipped_blacklist
    assert_equal 1, stats.items_skipped_duplicate

    # output should only include the single non-dup, non-blacklisted item
    assert_equal 1, stats.items_output
    rss = fusion.to_rss
    assert_includes rss, "<title>ok</title>"
    refute_includes rss, "<title>dup</title>"
    refute_includes rss, "<title>spam</title>"
  end

  def test_max_items_truncation
    fusion = FusionRss.new(blacklist_rules: [], max_items: 2)

    now = Time.now
    fusion.add(title: "one", url: "https://one.example/", published_at: now - 30, feed_name: "f")
    fusion.add(title: "two", url: "https://two.example/", published_at: now - 20, feed_name: "f")
    fusion.add(title: "three", url: "https://three.example/", published_at: now - 10, feed_name: "f")

    stats = Stats.new(feeds_total: 1)
    fusion.finalized(stats)

    # should be truncated to 2 items
    assert_equal 2, stats.items_output

    rss = fusion.to_rss
    assert_includes rss, "<title>three</title>"
    assert_includes rss, "<title>two</title>"
    refute_includes rss, "<title>one</title>"
  end

  def test_adding_duplicates_across_calls
    fusion = FusionRss.new(blacklist_rules: [], max_items: 10)

    now = Time.now
    fusion.add(title: "first", url: "https://dup.example/", published_at: now - 5, feed_name: "f")
    fusion.add(title: "second", url: "https://dup.example/", published_at: now, feed_name: "f")
    fusion.add(title: "third", url: "https://other.example/", published_at: now + 5, feed_name: "f")

    stats = Stats.new(feeds_total: 1)
    fusion.finalized(stats)

    # one duplicate should be counted
    assert_equal 1, stats.items_skipped_duplicate
    # output should include non-duplicate items only
    assert_equal 2, stats.items_output
    rss = fusion.to_rss
    assert_includes rss, "<title>third</title>"
    assert_includes rss, "<title>first</title>"
  end

  def test_to_rss_requires_finalize_first
    fusion = FusionRss.new(blacklist_rules: [], max_items: 10)
    now = Time.now
    fusion.add(title: "x", url: "https://x.example/", published_at: now, feed_name: "f")

    stats = Stats.new(feeds_total: 1)
    fusion.finalized(stats)

    # should not raise and should produce rss containing item title
    rss = fusion.to_rss
    assert_includes rss, "<title>x</title>"
  end
end