# frozen_string_literal: true

require_relative 'test_helper'

class FeedTest < Minitest::Test
  FakeGuid = Struct.new :content, :isPermaLink
  FakeEntry = Struct.new :title, :link, :guid, :pubDate, :description

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
      'hello',
      'https://example.com/post',
      published_at,
      'Example'

    assert_equal 'hello', feed.title
    assert_equal 'https://example.com/post', feed.url
    assert_equal published_at, feed.published_at
    assert_equal 'Example', feed.feed_name
    assert_equal [], feed.categories
  end

  def test_populate_entry_sets_rss_fields
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      'hello',
      'https://example.com/post',
      published_at,
      'Example'

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
      'hello',
      'https://example.com/post',
      published_at,
      'Example'

    maker = FakeMaker.new

    feed.to_rss_entry maker

    assert_equal 'hello', maker.items.entry.title
    assert_equal 'https://example.com/post', maker.items.entry.link
    assert_equal 'https://example.com/post', maker.items.entry.guid.content
    assert maker.items.entry.guid.isPermaLink
    assert_equal published_at, maker.items.entry.pubDate
  end

  def test_populate_entry_sets_description_when_summary_present
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      'hello',
      'https://example.com/post',
      published_at,
      'Example',
      summary: 'This is a summary.'

    entry = FakeEntry.new nil, nil, FakeGuid.new(nil, nil), nil, nil

    feed.populate_entry entry

    assert_equal 'This is a summary.', entry.description
  end

  def test_populate_entry_does_not_set_description_when_summary_absent
    published_at = Time.utc 2026, 2, 24, 5, 0, 0
    feed = FusionRss::FeedEntry.new \
      'hello',
      'https://example.com/post',
      published_at,
      'Example'

    entry = FakeEntry.new nil, nil, FakeGuid.new(nil, nil), nil, nil

    feed.populate_entry entry

    assert_nil entry.description
  end
end
