# frozen_string_literal: true

require_relative 'test_helper'

module FusionRssTestSupport
  def make_entry(title:, url:, published_at:, feed_name: 'f')
    FusionRss::FeedEntry.new(title: title, url: url, published_at: published_at, feed_name: feed_name)
  end

  def make_filter(*prefixes)
    obj = Object.new
    obj.instance_variable_set(:@prefixes, prefixes)
    obj.instance_variable_set(:@bl_count, 0)
    obj.define_singleton_method(:match?) do
      entry = it
      if @prefixes.any? { entry.url.start_with?(it) }
        @bl_count += 1
        true
      else
        false
      end
    end
    obj.define_singleton_method(:blacklisted_count) { @bl_count }
    obj.define_singleton_method(:unstable_count) { 0 }
    obj
  end
end

class FusionRssFinalizeTest < Minitest::Test
  include FusionRssTestSupport

  def test_finalize_updates_items_output_and_rss_order
    fusion = FusionRss.new(make_filter, 10)

    now = Time.now
    fusion.add(make_entry(title: 'old', url: 'https://a.example/', published_at: now - 60, feed_name: 'feedA'))
    fusion.add(make_entry(title: 'new', url: 'https://b.example/', published_at: now, feed_name: 'feedB'))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    assert_equal 2, stats.items_output

    rss = fusion.send(:to_rss)
    idx_new = rss.index('<title>new</title>')
    idx_old = rss.index('<title>old</title>')

    # newer item should appear before older one
    assert idx_new && idx_old
    assert idx_new < idx_old
  end

  def test_blacklist_and_duplicate_counting
    fusion = FusionRss.new(make_filter('https://spam.example/'), 10)

    now = Time.now
    # added item
    fusion.add(make_entry(title: 'ok', url: 'https://good.example/1', published_at: now - 30))
    # duplicate of the first
    fusion.add(make_entry(title: 'dup', url: 'https://good.example/1', published_at: now - 20))
    # blacklisted
    fusion.add(make_entry(title: 'spam', url: 'https://spam.example/1', published_at: now - 10))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    assert_equal 1, stats.items_skipped_blacklist
    assert_equal 1, stats.items_skipped_duplicate

    # output should only include the single non-dup, non-blacklisted item
    assert_equal 1, stats.items_output
    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>ok</title>'
    refute_includes rss, '<title>dup</title>'
    refute_includes rss, '<title>spam</title>'
  end

  def test_max_items_truncation
    fusion = FusionRss.new(make_filter, 2)

    now = Time.now
    fusion.add(make_entry(title: 'one',   url: 'https://one.example/',   published_at: now - 30))
    fusion.add(make_entry(title: 'two',   url: 'https://two.example/',   published_at: now - 20))
    fusion.add(make_entry(title: 'three', url: 'https://three.example/', published_at: now - 10))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    # should be truncated to 2 items
    assert_equal 2, stats.items_output

    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>three</title>'
    assert_includes rss, '<title>two</title>'
    refute_includes rss, '<title>one</title>'
  end

  def test_adding_duplicates_across_calls
    fusion = FusionRss.new(make_filter, 10)

    now = Time.now
    fusion.add(make_entry(title: 'first',  url: 'https://dup.example/',   published_at: now - 5))
    fusion.add(make_entry(title: 'second', url: 'https://dup.example/',   published_at: now))
    fusion.add(make_entry(title: 'third',  url: 'https://other.example/', published_at: now + 5))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    assert_equal 1, stats.items_skipped_duplicate
    assert_equal 2, stats.items_output
    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>third</title>'
    assert_includes rss, '<title>first</title>'
  end

  def test_to_rss_requires_finalize_first
    fusion = FusionRss.new(make_filter, 10)
    now = Time.now
    fusion.add(make_entry(title: 'x', url: 'https://x.example/', published_at: now))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    # should not raise and should produce rss containing item title
    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>x</title>'
  end
end

class FusionRssProcessTest < Minitest::Test
  include FusionRssTestSupport

  def test_process_entries_adds_valid_and_skips_blank_url
    fusion = FusionRss.new(make_filter, 10)
    now = Time.now

    entries = [
      FeedSource::FeedEntry.new(title: 'valid', url: 'https://good.example/1', published_at: now, feed_name: 'f'),
      FeedSource::FeedEntry.new(title: 'no url', url: nil, published_at: now, feed_name: 'f'),
      FeedSource::FeedEntry.new(title: 'blank url', url: '  ', published_at: now, feed_name: 'f')
    ]

    stats = Stats.new(feeds_total: 1)
    fusion.process_entries(entries, stats)

    assert_equal 3, stats.items_fetched
    assert_equal 2, stats.items_skipped_no_url

    stats.feed_succeeded
    fusion.finalize(stats)
    assert_equal 1, stats.items_output
  end

  def test_process_feed_on_success_increments_feed_succeeded
    fusion = FusionRss.new(make_filter, 10)
    now = Time.now
    entries = [
      FeedSource::FeedEntry.new(title: 'item', url: 'https://good.example/1', published_at: now, feed_name: 'src')
    ]

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'src' }
    feed_source.define_singleton_method(:url) { 'https://src.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { entries }

    stats = Stats.new(feeds_total: 1)
    fusion.process_feed(feed_source, stats)

    assert_equal 1, stats.feeds_succeeded
    assert_equal 0, stats.feeds_failed
    assert_equal 1, stats.items_fetched
  end

  def test_process_feed_on_failure_increments_feed_failed
    fusion = FusionRss.new(make_filter, 10)

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'broken' }
    feed_source.define_singleton_method(:url) { 'https://broken.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { raise 'network error' }

    stats = Stats.new(feeds_total: 1)
    fusion.process_feed(feed_source, stats)

    assert_equal 0, stats.feeds_succeeded
    assert_equal 1, stats.feeds_failed
    assert_equal 0, stats.items_fetched
  end
end
