# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class FusionRssBatchDuplicateTest < Minitest::Test
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

  def test_adding_duplicates_within_same_batch
    fusion = make_fusion 10

    now = Time.now
    fusion.send :add,
                make_entry(title: 'first', url: 'https://dup.example/', published_at: now - 5),
                make_entry(title: 'second', url: 'https://dup.example/', published_at: now),
                make_entry(title: 'third', url: 'https://other.example/', published_at: now + 5)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 1, stats.items_skipped_duplicate
    assert_equal 2, stats.items_output
    rss = fusion.send :to_rss
    assert_includes rss, '<title>third</title>'
    assert_includes rss, '<title>first</title>'
  end
end
