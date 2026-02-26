# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scripts/filter'

class FilterTest < Minitest::Test
  def make_blacklist(*prefixes)
    obj = Object.new
    obj.define_singleton_method(:match?) { |url| prefixes.any? { |p| url.start_with?(p) } }
    obj
  end

  def make_github_filter(*unstable_urls)
    obj = Object.new
    obj.define_singleton_method(:unstable?) { |url| unstable_urls.include?(url) }
    obj
  end

  def test_non_matching_url_returns_false
    filter = Filter.new(make_blacklist, make_github_filter)
    refute filter.match?('https://example.com/some/page')
  end

  def test_blacklisted_url_returns_true
    filter = Filter.new(make_blacklist('https://spam.example/'), make_github_filter)
    assert filter.match?('https://spam.example/post')
  end

  def test_unstable_url_returns_true
    filter = Filter.new(make_blacklist, make_github_filter('https://github.com/owner/repo/releases/tag/nightly'))
    assert filter.match?('https://github.com/owner/repo/releases/tag/nightly')
  end

  def test_blacklisted_increments_blacklisted_count
    filter = Filter.new(make_blacklist('https://spam.example/'), make_github_filter)
    filter.match?('https://spam.example/1')
    filter.match?('https://spam.example/2')
    assert_equal 2, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_unstable_increments_unstable_count
    filter = Filter.new(make_blacklist, make_github_filter('https://github.com/owner/repo/releases/tag/nightly'))
    filter.match?('https://github.com/owner/repo/releases/tag/nightly')
    assert_equal 0, filter.blacklisted_count
    assert_equal 1, filter.unstable_count
  end

  def test_non_matching_does_not_increment_counts
    filter = Filter.new(make_blacklist, make_github_filter)
    filter.match?('https://good.example/post')
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_blacklist_takes_priority_over_unstable
    # URL that matches both blacklist and unstable should be counted as blacklisted
    url = 'https://spam.example/releases/tag/nightly'
    filter = Filter.new(make_blacklist('https://spam.example/'), make_github_filter(url))
    assert filter.match?(url)
    assert_equal 1, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_initial_counts_are_zero
    filter = Filter.new(make_blacklist, make_github_filter)
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end
end
