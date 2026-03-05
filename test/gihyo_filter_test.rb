# frozen_string_literal: true

require_relative 'test_helper'

class GihyoFilterTest < Minitest::Test
  EntryStub = Struct.new :url, :title, :summary

  def setup
    @filter = Filter::GihyoFilter.new
  end

  # --- non-gihyo URLs (should always pass through) ---

  def test_non_gihyo_url_without_keyword_passes
    entry = EntryStub.new 'https://example.com/article', 'Random Article', nil
    refute @filter.reject?(entry)
  end

  def test_github_url_without_keyword_passes
    entry = EntryStub.new 'https://github.com/owner/repo', 'Some Repo', nil
    refute @filter.reject?(entry)
  end

  # --- gihyo.jp entries without matching keywords (should be rejected) ---

  def test_gihyo_entry_without_keyword_is_rejected
    entry = EntryStub.new 'https://gihyo.jp/article/123', 'Rubyの新機能', 'Rubyについての記事'
    assert @filter.reject?(entry)
  end

  def test_gihyo_entry_with_nil_title_and_nil_summary_is_rejected
    entry = EntryStub.new 'https://gihyo.jp/article/000', nil, nil
    assert @filter.reject?(entry)
  end

  # --- gihyo.jp entries with keywords in title (should pass through) ---

  def test_gihyo_entry_with_openapi_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/1', 'OpenAPIの使い方', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_chatgpt_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/2', 'ChatGPTで業務効率化', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_claude_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/3', 'Claude 3の実力', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_gemini_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/4', 'Geminiを試してみた', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_mcp_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/5', 'MCPサーバーの作り方', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_llama_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/6', 'Llamaでローカルモデルを動かす', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_qwen3_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/7', 'Qwen3のベンチマーク', nil
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_codex_in_title_passes
    entry = EntryStub.new 'https://gihyo.jp/article/8', 'Codexの紹介', nil
    refute @filter.reject?(entry)
  end

  # --- gihyo.jp entries with keywords in summary (should pass through) ---

  def test_gihyo_entry_with_chatgpt_in_summary_passes
    entry = EntryStub.new 'https://gihyo.jp/article/9', '最新AI情報', 'ChatGPTの活用事例を紹介'
    refute @filter.reject?(entry)
  end

  def test_gihyo_entry_with_gemini_in_summary_passes
    entry = EntryStub.new 'https://gihyo.jp/article/10', 'AI最新動向', 'GeminiとGPT-4の比較'
    refute @filter.reject?(entry)
  end

  # --- case-insensitive matching ---

  def test_keyword_match_is_case_insensitive_lowercase
    entry = EntryStub.new 'https://gihyo.jp/article/11', 'claude入門', nil
    refute @filter.reject?(entry)
  end

  def test_keyword_match_is_case_insensitive_uppercase
    entry = EntryStub.new 'https://gihyo.jp/article/12', 'CHATGPT活用術', nil
    refute @filter.reject?(entry)
  end
end
