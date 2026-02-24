# frozen_string_literal: true

require "minitest/autorun"
require_relative "stats"

class StatsTest < Minitest::Test
  def setup
    @stats = Stats.new(feeds_total: 5)
  end

  def test_initial_values
    assert_equal 5, @stats.feeds_total
    assert_equal 0, @stats.feeds_succeeded
    assert_equal 0, @stats.feeds_failed
    assert_equal 0, @stats.items_fetched
    assert_equal 0, @stats.items_skipped_no_url
    assert_equal 0, @stats.items_skipped_blacklist
    assert_equal 0, @stats.items_skipped_duplicate
    assert_equal 0, @stats.items_output
  end

  def test_feed_succeeded
    @stats.feed_succeeded
    assert_equal 1, @stats.feeds_succeeded
  end

  def test_feed_succeeded_multiple
    3.times { @stats.feed_succeeded }
    assert_equal 3, @stats.feeds_succeeded
  end

  def test_feed_failed
    @stats.feed_failed
    assert_equal 1, @stats.feeds_failed
  end

  def test_feed_failed_multiple
    2.times { @stats.feed_failed }
    assert_equal 2, @stats.feeds_failed
  end

  def test_item_fetched
    @stats.item_fetched
    assert_equal 1, @stats.items_fetched
  end

  def test_item_fetched_multiple
    5.times { @stats.item_fetched }
    assert_equal 5, @stats.items_fetched
  end

  def test_item_skipped_no_url
    @stats.item_skipped_no_url
    assert_equal 1, @stats.items_skipped_no_url
  end

  def test_item_skipped_blacklist
    @stats.item_skipped_blacklist
    assert_equal 1, @stats.items_skipped_blacklist
  end

  def test_item_skipped_duplicate
    @stats.item_skipped_duplicate
    assert_equal 1, @stats.items_skipped_duplicate
  end

  def test_finalize
    @stats.finalize(10)
    assert_equal 10, @stats.items_output
  end

  def test_finalize_overwrites
    @stats.finalize(10)
    @stats.finalize(7)
    assert_equal 7, @stats.items_output
  end

  def test_summary_feeds_line
    3.times { @stats.feed_succeeded }
    2.times { @stats.feed_failed }
    assert_equal "feeds total=5 success=3 failed=2", @stats.summary[0]
  end

  def test_summary_items_line
    10.times { @stats.item_fetched }
    @stats.item_skipped_no_url
    2.times { @stats.item_skipped_blacklist }
    3.times { @stats.item_skipped_duplicate }
    @stats.finalize(4)
    assert_equal "items fetched=10 skipped_no_url=1 skipped_blacklist=2 skipped_duplicate=3 output=4", @stats.summary[1]
  end

  def test_summary_returns_two_lines
    assert_equal 2, @stats.summary.length
  end

  def test_counters_are_independent
    @stats.feed_succeeded
    @stats.feed_failed
    @stats.item_fetched
    @stats.item_skipped_no_url
    @stats.item_skipped_blacklist
    @stats.item_skipped_duplicate

    assert_equal 1, @stats.feeds_succeeded
    assert_equal 1, @stats.feeds_failed
    assert_equal 1, @stats.items_fetched
    assert_equal 1, @stats.items_skipped_no_url
    assert_equal 1, @stats.items_skipped_blacklist
    assert_equal 1, @stats.items_skipped_duplicate
  end
end