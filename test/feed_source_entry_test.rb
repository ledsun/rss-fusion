# frozen_string_literal: true

require_relative 'test_helper'

class FeedSourceEntryTest < Minitest::Test
  def test_feed_entry_uses_summary_when_present
    raw = Struct.new(:title, :url, :published, :summary).new \
      'Hello',
      'https://example.com/hello',
      Time.utc(2026, 2, 28, 0, 0, 0),
      'This is a summary.'

    entry = FeedSource::FeedEntry.new raw, 'Sample', Time.utc(2026, 2, 28, 0, 0, 0)

    assert_equal 'This is a summary.', entry.summary
  end

  def test_feed_entry_falls_back_to_content_when_summary_absent
    raw = Struct.new(:title, :url, :published, :content).new \
      'Hello',
      'https://example.com/hello',
      Time.utc(2026, 2, 28, 0, 0, 0),
      'This is content.'

    entry = FeedSource::FeedEntry.new raw, 'Sample', Time.utc(2026, 2, 28, 0, 0, 0)

    assert_equal 'This is content.', entry.summary
  end

  def test_feed_entry_summary_is_nil_when_neither_summary_nor_content_present
    raw = Struct.new(:title, :url, :published).new \
      'Hello',
      'https://example.com/hello',
      Time.utc(2026, 2, 28, 0, 0, 0)

    entry = FeedSource::FeedEntry.new raw, 'Sample', Time.utc(2026, 2, 28, 0, 0, 0)

    assert_nil entry.summary
  end
end
