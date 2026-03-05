# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

module FusionRssTestSupport
  def make_entry(title:, url:, published_at:, feed_name: 'f')
    FusionRss::FeedEntry.new title:, url:, published_at:, feed_name:
  end

  def make_fusion(max_feeds, *prefixes)
    fusion = nil
    Dir.mktmpdir 'fusion-rss-test-' do |dir|
      path = File.join dir, 'blacklist.txt'
      File.write path, prefixes.join("\n")
      fusion = FusionRss.new max_feeds, path
    end
    fusion
  end
end

class FusionRssFinalizeTest < Minitest::Test
  include FusionRssTestSupport

  def test_finalize_updates_items_output_and_rss_order
    fusion = make_fusion 10

    now = Time.now
    fusion.send :add, make_entry(title: 'old', url: 'https://a.example/', published_at: now - 60, feed_name: 'feedA')
    fusion.send :add, make_entry(title: 'new', url: 'https://b.example/', published_at: now, feed_name: 'feedB')

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 2, stats.items_output

    rss = fusion.send :to_rss
    idx_new = rss.index '<title>new</title>'
    idx_old = rss.index '<title>old</title>'

    # newer item should appear before older one
    assert idx_new && idx_old
    assert idx_new < idx_old
  end

  def test_blacklist_and_duplicate_counting
    fusion = make_fusion 10, 'https://spam.example/'

    now = Time.now
    # added item
    fusion.send :add, make_entry(title: 'ok', url: 'https://good.example/1', published_at: now - 30)
    # duplicate of the first
    fusion.send :add, make_entry(title: 'dup', url: 'https://good.example/1', published_at: now - 20)
    # blacklisted
    fusion.send :add, make_entry(title: 'spam', url: 'https://spam.example/1', published_at: now - 10)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 1, stats.items_skipped_blacklist
    assert_equal 1, stats.items_skipped_duplicate

    # output should only include the single non-dup, non-blacklisted item
    assert_equal 1, stats.items_output
    rss = fusion.send :to_rss
    assert_includes rss, '<title>ok</title>'
    refute_includes rss, '<title>dup</title>'
    refute_includes rss, '<title>spam</title>'
  end

  def test_max_items_truncation
    fusion = make_fusion 2

    now = Time.now
    fusion.send :add, make_entry(title: 'one',   url: 'https://one.example/',   published_at: now - 30)
    fusion.send :add, make_entry(title: 'two',   url: 'https://two.example/',   published_at: now - 20)
    fusion.send :add, make_entry(title: 'three', url: 'https://three.example/', published_at: now - 10)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    # should be truncated to 2 items
    assert_equal 2, stats.items_output

    rss = fusion.send :to_rss
    assert_includes rss, '<title>three</title>'
    assert_includes rss, '<title>two</title>'
    refute_includes rss, '<title>one</title>'
  end

  def test_adding_duplicates_across_calls
    fusion = make_fusion 10

    now = Time.now
    fusion.send :add, make_entry(title: 'first',  url: 'https://dup.example/',   published_at: now - 5)
    fusion.send :add, make_entry(title: 'second', url: 'https://dup.example/',   published_at: now)
    fusion.send :add, make_entry(title: 'third',  url: 'https://other.example/', published_at: now + 5)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 1, stats.items_skipped_duplicate
    assert_equal 2, stats.items_output
    rss = fusion.send :to_rss
    assert_includes rss, '<title>third</title>'
    assert_includes rss, '<title>first</title>'
  end

  def test_to_rss_requires_finalize_first
    fusion = make_fusion 10
    now = Time.now
    fusion.send :add, make_entry(title: 'x', url: 'https://x.example/', published_at: now)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    # should not raise and should produce rss containing item title
    rss = fusion.send :to_rss
    assert_includes rss, '<title>x</title>'
  end
end

class FusionRssProcessTest < Minitest::Test
  include FusionRssTestSupport

  FakeRawEntry = Struct.new :title, :url, :published

  def make_feed_entry(title:, url:, published_at:, feed_name:)
    FeedSource::FeedEntry.new \
      FakeRawEntry.new(title, url, published_at),
      feed_name:,
      fetched_at: published_at
  end

  def test_process_entries_adds_valid_and_skips_blank_url
    fusion = make_fusion 10
    now = Time.now

    entries = [
      make_feed_entry(title: 'valid', url: 'https://good.example/1', published_at: now, feed_name: 'f'),
      make_feed_entry(title: 'no url', url: nil, published_at: now, feed_name: 'f'),
      make_feed_entry(title: 'blank url', url: '  ', published_at: now, feed_name: 'f')
    ]

    stats = Stats.new feeds_total: 1
    fusion.send :process_entries, entries, stats

    assert_equal 3, stats.items_fetched
    assert_equal 2, stats.items_skipped_no_url

    stats.feed_succeeded
    fusion.send :finalize, stats
    assert_equal 1, stats.items_output
  end

  def test_process_feed_on_success_increments_feed_succeeded
    fusion = make_fusion 10
    now = Time.now
    entries = [
      make_feed_entry(title: 'item', url: 'https://good.example/1', published_at: now, feed_name: 'src')
    ]

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'src' }
    feed_source.define_singleton_method(:url) { 'https://src.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { entries }

    stats = Stats.new feeds_total: 1
    fusion.send :process_feed, feed_source, stats

    assert_equal 1, stats.feeds_succeeded
    assert_equal 0, stats.feeds_failed
    assert_equal 1, stats.items_fetched
  end

  def test_process_feed_on_failure_increments_feed_failed
    fusion = make_fusion 10

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'broken' }
    feed_source.define_singleton_method(:url) { 'https://broken.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { raise 'network error' }

    stats = Stats.new feeds_total: 1
    fusion.send :process_feed, feed_source, stats

    assert_equal 0, stats.feeds_succeeded
    assert_equal 1, stats.feeds_failed
    assert_equal 0, stats.items_fetched
  end

  def test_process_initializes_stats_and_finalizes
    fusion = make_fusion 10
    now = Time.now
    entries = [
      make_feed_entry(title: 'item', url: 'https://good.example/1', published_at: now, feed_name: 'src')
    ]

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'src' }
    feed_source.define_singleton_method(:url) { 'https://src.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { entries }

    result = fusion.process [feed_source]

    assert_equal 1, result.feeds_total
    assert_equal 1, result.feeds_succeeded
    assert_equal 1, result.items_output
  end
end
