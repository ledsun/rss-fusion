# frozen_string_literal: true

require 'minitest/autorun'
require 'stringio'
require_relative '../lib/feed_source'

class FeedSourceTest < Minitest::Test
  def sample_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Sample Feed</title>
          <item>
            <title>Hello</title>
            <link>https://example.com/hello</link>
            <pubDate>Fri, 27 Feb 2026 00:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    XML
  end

  def test_fetch_entries_reads_response_and_parses_fields
    rss = FeedSource.new(name: 'Sample', url: 'https://example.com/feed')
    with_stubbed_uri_open(sample_xml) do
      entries = rss.fetch_entries
      assert_equal 1, entries.length
      assert_equal 'Hello', entries[0].title
      assert_equal 'https://example.com/hello', entries[0].url
      assert_equal 'Sample', entries[0].feed_name
      assert_instance_of Time, entries[0].published_at

      assert_equal true, it[:called]
      assert_equal 'https://example.com/feed', it[:url]
      assert_equal true, it[:has_block]
      assert_equal 'rss-merge-bot/0.1', it[:options]['User-Agent']
      assert_equal 'no-cache', it[:options]['Cache-Control']
      assert_equal 'no-cache', it[:options]['Pragma']
    end
  end

  def test_feed_entry_url_blank_is_true_for_nil_or_blank_like_values
    assert_equal true, build_feed_entry(url: nil).url_blank?
    assert_equal true, build_feed_entry(url: '').url_blank?
    assert_equal true, build_feed_entry(url: '   ').url_blank?
  end

  def test_feed_entry_url_blank_is_false_for_non_blank_url
    assert_equal false, build_feed_entry(url: 'https://example.com/post').url_blank?
  end

  private

  def build_feed_entry(url:)
    FeedSource::FeedEntry.new(
      title: 'Title',
      url: url,
      published_at: Time.utc(2026, 2, 28, 0, 0, 0),
      feed_name: 'Sample'
    )
  end

  def with_stubbed_uri_open(xml)
    original_open = URI.method(:open)
    probe = { called: false, url: nil, has_block: false, options: {} }

    URI.define_singleton_method(:open) do |*args, &block|
      probe[:called] = true
      probe[:url] = args[0]
      probe[:has_block] = !block.nil?
      probe[:options] = args.drop(1).select { it.is_a?(Hash) }.reduce({}) { |acc, h| acc.merge(h) }
      block.call(StringIO.new(xml))
    end

    yield probe
  ensure
    URI.define_singleton_method(:open, original_open)
  end
end
