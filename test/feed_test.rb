# frozen_string_literal: true

require_relative 'test_helper'

class FeedTest < Minitest::Test
  FakeGuid = Struct.new :content, :isPermaLink
  FakeEntry = Struct.new :title, :link, :guid, :pubDate

  class FakeItems
    attr_reader :entry

    def new_item
      @entry = FakeEntry.new nil, nil, FakeGuid.new(nil, nil), nil
      yield @entry
    end
  end

  class FakeMaker
    attr_reader :items

    def initialize
      @items = FakeItems.new
    end
  end

  def test_initializes_attributes
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      title: 'hello',
      url: 'https://example.com/post',
      published_at:,
      feed_name: 'Example'

    assert_equal 'hello', feed.title
    assert_equal 'https://example.com/post', feed.url
    assert_equal published_at, feed.published_at
    assert_equal 'Example', feed.feed_name
  end

  def test_populate_entry_sets_rss_fields
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      title: 'hello',
      url: 'https://example.com/post',
      published_at:,
      feed_name: 'Example'

    entry = FakeEntry.new nil, nil, FakeGuid.new(nil, nil), nil

    feed.populate_entry entry

    assert_equal 'hello', entry.title
    assert_equal 'https://example.com/post', entry.link
    assert_equal 'https://example.com/post', entry.guid.content
    assert entry.guid.isPermaLink
    assert_equal published_at, entry.pubDate
  end

  def test_to_rss_entry_adds_new_item_and_populates_fields
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      title: 'hello',
      url: 'https://example.com/post',
      published_at:,
      feed_name: 'Example'

    maker = FakeMaker.new

    feed.to_rss_entry maker

    assert_equal 'hello', maker.items.entry.title
    assert_equal 'https://example.com/post', maker.items.entry.link
    assert_equal 'https://example.com/post', maker.items.entry.guid.content
    assert maker.items.entry.guid.isPermaLink
    assert_equal published_at, maker.items.entry.pubDate
  end
end
