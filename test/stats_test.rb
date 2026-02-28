# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/stats'

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
    assert_equal 0, @stats.items_skipped_unstable
    assert_equal 0, @stats.items_output
  end

  def test_feed_succeeded_and_multiple
    @stats.feed_succeeded
    2.times { @stats.feed_succeeded }
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
    @stats.item_fetched(1)
    assert_equal 1, @stats.items_fetched
  end

  def test_item_fetched_with_count
    @stats.item_fetched(7)
    assert_equal 7, @stats.items_fetched
  end

  def test_item_skipped_no_url_with_count
    @stats.item_skipped_no_url(4)
    assert_equal 4, @stats.items_skipped_no_url
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
    @stats.finalize(output: 10, blacklisted: 0, duplicate: 0)
    assert_equal 10, @stats.items_output
  end

  def test_finalize_overwrites
    @stats.finalize(output: 10, blacklisted: 0, duplicate: 0)
    @stats.finalize(output: 7, blacklisted: 0, duplicate: 0)
    assert_equal 7, @stats.items_output
  end

  def test_finalize_updates_blacklisted
    @stats.finalize(output: 5, blacklisted: 3, duplicate: 0)
    assert_equal 3, @stats.items_skipped_blacklist
  end

  def test_finalize_updates_duplicate
    @stats.finalize(output: 5, blacklisted: 0, duplicate: 2)
    assert_equal 2, @stats.items_skipped_duplicate
  end

  def test_finalize_updates_unstable
    @stats.finalize(output: 5, blacklisted: 0, duplicate: 0, unstable: 4)
    assert_equal 4, @stats.items_skipped_unstable
  end

  def test_summary_feeds_line
    3.times { @stats.feed_succeeded }
    2.times { @stats.feed_failed }
    assert_equal 'feeds total=5 success=3 failed=2', @stats.summary[0]
  end

  def test_summary_items_line
    @stats.item_fetched(10)
    @stats.item_skipped_no_url(1)
    @stats.finalize(output: 4, blacklisted: 2, duplicate: 3, unstable: 1)
    summary = 'items fetched=10 skipped_no_url=1 skipped_blacklist=2 ' \
              'skipped_duplicate=3 skipped_unstable=1 output=4'
    assert_equal summary, @stats.summary[1]
  end

  def test_summary_returns_two_lines
    assert_equal 2, @stats.summary.length
  end

  def test_counters_are_independent
    @stats.feed_succeeded
    @stats.feed_failed
    @stats.item_fetched(1)
    @stats.item_skipped_no_url(1)
    @stats.finalize(output: 0, blacklisted: 1, duplicate: 1, unstable: 2)

    assert_equal 1, @stats.feeds_succeeded
    assert_equal 1, @stats.feeds_failed
    assert_equal 1, @stats.items_fetched
    assert_equal 1, @stats.items_skipped_no_url
    assert_equal 1, @stats.items_skipped_blacklist
    assert_equal 1, @stats.items_skipped_duplicate
    assert_equal 2, @stats.items_skipped_unstable
  end
end
