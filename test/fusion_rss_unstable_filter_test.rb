# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class FusionRssUnstableFilterTest < Minitest::Test
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

  def test_unstable_github_releases_are_filtered
    fusion = make_fusion 10

    now = Time.now
    base = 'https://github.com/owner/repo/releases/tag/'
    fusion.send :add, make_entry(title: 'stable', url: "#{base}v1.0.0", published_at: now - 30)
    fusion.send :add, make_entry(title: 'alpha',   url: "#{base}v1.0.0-alpha.1", published_at: now - 20)
    fusion.send :add, make_entry(title: 'nightly', url: "#{base}nightly",        published_at: now - 10)
    fusion.send :add, make_entry(title: 'pre',     url: "#{base}v1.1.0-pre",     published_at: now)

    stats = Stats.new feeds_total: 1
    fusion.send :finalize, stats

    assert_equal 1, stats.items_output
    assert_equal 3, stats.items_skipped_unstable

    rss = fusion.send :to_rss
    assert_includes rss, '<title>stable</title>'
    refute_includes rss, '<title>alpha</title>'
    refute_includes rss, '<title>nightly</title>'
    refute_includes rss, '<title>pre</title>'
  end
end
