# frozen_string_literal: true

require_relative 'test_helper'
require 'rss'
require 'tmpdir'

module FusionRssTestSupport
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

class FusionRssProcessTest < Minitest::Test
  include FusionRssTestSupport

  FakeRawEntry = Struct.new :title, :url, :published
  FakeCatalog = Struct.new :sources do
    def length = sources.length
  end

  def make_feed_entry(title:, url:, published_at:, feed_name:)
    FeedSource::FeedEntry.new \
      FakeRawEntry.new(title, url, published_at),
      feed_name,
      published_at
  end

  def test_ingest_adds_valid_and_skips_blank_url
    fusion = make_fusion 10
    now = Time.now

    entries = [
      make_feed_entry(title: 'valid', url: 'https://good.example/1', published_at: now, feed_name: 'f'),
      make_feed_entry(title: 'no url', url: nil, published_at: now, feed_name: 'f'),
      make_feed_entry(title: 'blank url', url: '  ', published_at: now, feed_name: 'f')
    ]

    stats = Stats.new 1
    fusion.send :ingest, entries, stats

    assert_equal 3, stats.items_fetched
    assert_equal 2, stats.items_skipped_no_url

    stats.feed_succeeded
    fusion.send :finalize, stats
    assert_equal 1, stats.items_output
  end

  def test_fetch_from_on_success_increments_feed_succeeded
    fusion = make_fusion 10
    now = Time.now
    entries = [
      make_feed_entry(title: 'item', url: 'https://good.example/1', published_at: now, feed_name: 'src')
    ]

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'src' }
    feed_source.define_singleton_method(:url) { 'https://src.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { entries }

    stats = Stats.new 1
    fusion.send :fetch_from, feed_source, stats

    assert_equal 1, stats.feeds_succeeded
    assert_equal 0, stats.feeds_failed
    assert_equal 1, stats.items_fetched
  end

  def test_fetch_from_on_failure_increments_feed_failed
    fusion = make_fusion 10

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'broken' }
    feed_source.define_singleton_method(:url) { 'https://broken.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { raise 'network error' }

    stats = Stats.new 1
    fusion.send :fetch_from, feed_source, stats

    assert_equal 0, stats.feeds_succeeded
    assert_equal 1, stats.feeds_failed
    assert_equal 0, stats.items_fetched
  end

  def test_write_to_uses_custom_channel_metadata
    now = Time.now
    entries = [
      make_feed_entry(title: 'item', url: 'https://good.example/1', published_at: now, feed_name: 'src')
    ]

    feed_source = Object.new
    feed_source.define_singleton_method(:name) { 'src' }
    feed_source.define_singleton_method(:url) { 'https://src.example/feed' }
    feed_source.define_singleton_method(:fetch_entries) { entries }

    Dir.mktmpdir 'fusion-rss-test-' do
      blacklist_path = File.join it, 'blacklist.txt'
      output_path = File.join it, 'news.xml'
      File.write blacklist_path, ''

      fusion = FusionRss.new 10, blacklist_path, 'RSS Fusion News', 'News-only feed'
      fusion.process FakeCatalog.new([feed_source])
      fusion.write_to output_path

      rss = RSS::Parser.parse File.read(output_path)
      assert_equal 'RSS Fusion News', rss.channel.title
      assert_equal 'News-only feed', rss.channel.description
    end
  end
end
