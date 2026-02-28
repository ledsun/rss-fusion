# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/filter'

class FilterTest < Minitest::Test
  STABLE_URL   = 'https://github.com/owner/repo/releases/tag/v1.0.0'
  UNSTABLE_URL = 'https://github.com/owner/repo/releases/tag/v1.0.0-alpha.1'
  NIGHTLY_URL  = 'https://github.com/owner/repo/releases/tag/nightly'

  def make_blacklist(*prefixes)
    obj = Object.new
    obj.define_singleton_method(:match?) { |url| prefixes.any? { |p| url.start_with?(p) } }
    obj
  end

  def test_non_matching_url_returns_false
    filter = Filter.new(make_blacklist)
    refute filter.match?('https://example.com/some/page')
  end

  def test_stable_github_release_url_returns_false
    filter = Filter.new(make_blacklist)
    refute filter.match?(STABLE_URL)
  end

  def test_blacklisted_url_returns_true
    filter = Filter.new(make_blacklist('https://spam.example/'))
    assert filter.match?('https://spam.example/post')
  end

  def test_unstable_github_release_url_returns_true
    filter = Filter.new(make_blacklist)
    assert filter.match?(UNSTABLE_URL)
  end

  def test_nightly_github_release_url_returns_true
    filter = Filter.new(make_blacklist)
    assert filter.match?(NIGHTLY_URL)
  end

  def test_blacklisted_increments_blacklisted_count
    filter = Filter.new(make_blacklist('https://spam.example/'))
    filter.match?('https://spam.example/1')
    filter.match?('https://spam.example/2')
    assert_equal 2, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_unstable_increments_unstable_count
    filter = Filter.new(make_blacklist)
    filter.match?(UNSTABLE_URL)
    assert_equal 0, filter.blacklisted_count
    assert_equal 1, filter.unstable_count
  end

  def test_non_matching_does_not_increment_counts
    filter = Filter.new(make_blacklist)
    filter.match?('https://good.example/post')
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_blacklist_takes_priority_over_unstable
    # A blacklisted URL that also looks unstable should be counted as blacklisted
    url = 'https://spam.example/releases/tag/nightly'
    filter = Filter.new(make_blacklist('https://spam.example/'))
    assert filter.match?(url)
    assert_equal 1, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_initial_counts_are_zero
    filter = Filter.new(make_blacklist)
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end
end
