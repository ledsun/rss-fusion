# frozen_string_literal: true

require_relative 'test_helper'

class PublickeyFilterTest < Minitest::Test
  EntryStub = Struct.new :url, :categories

  def setup
    @filter = Filter::PublickeyFilter.new
  end

  def test_non_publickey_url_passes
    entry = EntryStub.new 'https://example.com/article', ['機械学習・AI']
    refute @filter.reject?(entry)
  end

  def test_publickey_entry_without_ai_category_is_rejected
    entry = EntryStub.new 'https://www.publickey1.jp/blog/26/web_article.html', %w[JavaScript Web技術]
    assert @filter.reject?(entry)
  end

  def test_publickey_entry_with_ai_category_passes
    entry = EntryStub.new 'https://www.publickey1.jp/blog/26/ai_article.html',
                          ['Windows', '機械学習・AI', '開発ツール']
    refute @filter.reject?(entry)
  end

  def test_publickey_entry_with_nil_categories_is_rejected
    entry = EntryStub.new 'https://www.publickey1.jp/blog/26/unknown.html', nil
    assert @filter.reject?(entry)
  end
end
