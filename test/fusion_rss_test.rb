# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scripts/fusion_rss'
require_relative '../scripts/stats'
require_relative '../scripts/github_release_filter'

class FusionRssTest < Minitest::Test
  def make_entry(title:, url:, published_at:, feed_name: 'f')
    FusionRss::FeedEntry.new(title: title, url: url, published_at: published_at, feed_name: feed_name)
  end

  def make_blacklist(*prefixes)
    obj = Object.new
    obj.define_singleton_method(:match?) { |url| prefixes.any? { |p| url.start_with?(p) } }
    obj
  end

  def test_finalize_updates_items_output_and_rss_order
    fusion = FusionRss.new(make_blacklist, 10)

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
    fusion = FusionRss.new(make_blacklist('https://spam.example/'), 10)

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
    fusion = FusionRss.new(make_blacklist, 2)

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
    fusion = FusionRss.new(make_blacklist, 10)

    now = Time.now
    fusion.add(make_entry(title: 'first',  url: 'https://dup.example/',   published_at: now - 5))
    fusion.add(make_entry(title: 'second', url: 'https://dup.example/',   published_at: now))
    fusion.add(make_entry(title: 'third',  url: 'https://other.example/', published_at: now + 5))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    # one duplicate should be counted
    assert_equal 1, stats.items_skipped_duplicate
    # output should include non-duplicate items only
    assert_equal 2, stats.items_output
    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>third</title>'
    assert_includes rss, '<title>first</title>'
  end

  def test_to_rss_requires_finalize_first
    fusion = FusionRss.new(make_blacklist, 10)
    now = Time.now
    fusion.add(make_entry(title: 'x', url: 'https://x.example/', published_at: now))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    # should not raise and should produce rss containing item title
    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>x</title>'
  end

  def test_unstable_github_releases_are_filtered
    filter = GithubReleaseFilter.new
    fusion = FusionRss.new(make_blacklist, 10, github_release_filter: filter)

    now = Time.now
    fusion.add(make_entry(title: 'stable',   url: 'https://github.com/owner/repo/releases/tag/v1.0.0',          published_at: now - 30))
    fusion.add(make_entry(title: 'alpha',    url: 'https://github.com/owner/repo/releases/tag/v1.0.0-alpha.1',  published_at: now - 20))
    fusion.add(make_entry(title: 'nightly',  url: 'https://github.com/owner/repo/releases/tag/nightly',         published_at: now - 10))
    fusion.add(make_entry(title: 'pre',      url: 'https://github.com/owner/repo/releases/tag/v1.1.0-pre',      published_at: now))

    stats = Stats.new(feeds_total: 1)
    fusion.finalize(stats)

    assert_equal 1, stats.items_output
    assert_equal 3, stats.items_skipped_unstable

    rss = fusion.send(:to_rss)
    assert_includes rss, '<title>stable</title>'
    refute_includes rss, '<title>alpha</title>'
    refute_includes rss, '<title>nightly</title>'
    refute_includes rss, '<title>pre</title>'
  end
end
