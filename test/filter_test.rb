# frozen_string_literal: true

require_relative 'test_helper'

class FilterTest < Minitest::Test
  EntryStub = Struct.new :url, :title, :summary, :categories

  STABLE_URL        = 'https://github.com/owner/repo/releases/tag/v1.0.0'
  UNSTABLE_URL      = 'https://github.com/owner/repo/releases/tag/v1.0.0-alpha.1'
  NIGHTLY_URL       = 'https://github.com/owner/repo/releases/tag/nightly'
  PUBLICKEY_AI_URL  = 'https://www.publickey1.jp/blog/26/ai_article.html'
  PUBLICKEY_WEB_URL = 'https://www.publickey1.jp/blog/26/web_article.html'

  def make_entry(url, title: '', summary: nil, categories: [])
    EntryStub.new url, title, summary, categories
  end

  def make_blacklist(*prefixes)
    obj = Object.new
    obj.define_singleton_method :match? do
      url = it
      prefixes.any? { url.start_with? it }
    end
    obj
  end

  def test_non_matching_url_returns_false
    filter = Filter.new make_blacklist
    refute_operator filter, :match?, make_entry('https://example.com/some/page')
  end

  def test_stable_github_release_url_returns_false
    filter = Filter.new make_blacklist
    refute_operator filter, :match?, make_entry(STABLE_URL)
  end

  def test_blacklisted_url_returns_true
    filter = Filter.new make_blacklist('https://spam.example/')
    assert_operator filter, :match?, make_entry('https://spam.example/post')
  end

  def test_unstable_github_release_url_returns_true
    filter = Filter.new make_blacklist
    assert_operator filter, :match?, make_entry(UNSTABLE_URL)
  end

  def test_nightly_github_release_url_returns_true
    filter = Filter.new make_blacklist
    assert_operator filter, :match?, make_entry(NIGHTLY_URL)
  end

  def test_blacklisted_increments_blacklisted_count
    filter = Filter.new make_blacklist('https://spam.example/')
    filter.match? make_entry('https://spam.example/1')
    filter.match? make_entry('https://spam.example/2')
    assert_equal 2, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_unstable_increments_unstable_count
    filter = Filter.new make_blacklist
    filter.match? make_entry(UNSTABLE_URL)
    assert_equal 0, filter.blacklisted_count
    assert_equal 1, filter.unstable_count
  end

  def test_non_matching_does_not_increment_counts
    filter = Filter.new make_blacklist
    filter.match? make_entry('https://good.example/post')
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_blacklist_takes_priority_over_unstable
    # A blacklisted URL that also looks unstable should be counted as blacklisted
    url = 'https://spam.example/releases/tag/nightly'
    filter = Filter.new make_blacklist('https://spam.example/')
    assert_operator filter, :match?, make_entry(url)
    assert_equal 1, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_initial_counts_are_zero
    filter = Filter.new make_blacklist
    assert_equal 0, filter.blacklisted_count
    assert_equal 0, filter.unstable_count
  end

  def test_gihyo_entry_without_keyword_is_filtered
    filter = Filter.new make_blacklist
    entry = make_entry 'https://gihyo.jp/article/123', title: 'Rubyの新機能', summary: 'Rubyについての記事'
    assert_operator filter, :match?, entry
  end

  def test_gihyo_entry_with_keyword_in_title_passes
    filter = Filter.new make_blacklist
    entry = make_entry 'https://gihyo.jp/article/456', title: 'Claude 3の使い方', summary: 'AI記事'
    refute_operator filter, :match?, entry
  end

  def test_gihyo_entry_with_keyword_in_summary_passes
    filter = Filter.new make_blacklist
    entry = make_entry 'https://gihyo.jp/article/789', title: '最新AI情報', summary: 'ChatGPTの活用事例'
    refute_operator filter, :match?, entry
  end

  def test_non_gihyo_entry_without_keyword_passes
    filter = Filter.new make_blacklist
    entry = make_entry 'https://example.com/article', title: 'Some Article', summary: 'Some content'
    refute_operator filter, :match?, entry
  end

  def test_publickey_entry_without_ai_category_is_filtered
    filter = Filter.new make_blacklist
    entry = make_entry PUBLICKEY_WEB_URL, title: 'React Foundation', categories: %w[JavaScript Web技術]
    assert_operator filter, :match?, entry
  end

  def test_publickey_entry_with_ai_category_passes
    filter = Filter.new make_blacklist
    entry = make_entry PUBLICKEY_AI_URL, title: 'Codex for Windows', categories: %w[Windows 機械学習・AI 開発ツール]
    refute_operator filter, :match?, entry
  end
end
