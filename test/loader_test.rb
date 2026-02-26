# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../scripts/loader'

class LoaderTest < Minitest::Test
  def with_temp_feeds_file(content)
    Dir.mktmpdir('loader-test-') do |dir|
      path = File.join(dir, 'feeds.yml')
      File.write(path, content)
      yield path
    end
  end

  def test_loads_feeds_and_exposes_each_and_size
    yaml = <<~YAML
      feeds:
        - name: Zenn
          url: https://zenn.dev/topics/codex/feed
        - name: Qiita
          url: https://qiita.com/tags/codex/feed
    YAML

    with_temp_feeds_file(yaml) do |path|
      loader = Loader.new(path)

      assert_equal 2, loader.length
      assert_equal 2, loader.size
      assert_equal 'Zenn',                                loader.to_a[0].name
      assert_equal 'https://zenn.dev/topics/codex/feed',  loader.to_a[0].url
      assert_equal 'Qiita',                               loader.to_a[1].name
      assert_equal 'https://qiita.com/tags/codex/feed',   loader.to_a[1].url
    end
  end

  def test_raises_when_top_level_feeds_is_missing
    with_temp_feeds_file("not_feeds: []\n") do |path|
      error = assert_raises(Loader::ConfigFormatError) { Loader.new(path) }
      assert_includes error.message, "top-level 'feeds' array is required"
    end
  end

  def test_raises_when_feed_row_is_not_mapping
    yaml = <<~YAML
      feeds:
        - just-a-string
    YAML

    with_temp_feeds_file(yaml) do |path|
      error = assert_raises(Loader::ConfigFormatError) { Loader.new(path) }
      assert_includes error.message, 'expected mapping'
    end
  end

  def test_raises_when_name_or_url_missing
    yaml = <<~YAML
      feeds:
        - name: OnlyName
    YAML

    with_temp_feeds_file(yaml) do |path|
      error = assert_raises(Loader::ConfigFormatError) { Loader.new(path) }
      assert_includes error.message, 'name and url are required'
    end
  end

  def test_raises_when_yaml_syntax_is_invalid
    yaml = <<~YAML
      feeds:
        - name: Broken
          url: https://example.com
        - name: Oops: [bad
    YAML

    with_temp_feeds_file(yaml) do |path|
      error = assert_raises(Loader::ConfigFormatError) { Loader.new(path) }
      assert_includes error.message, 'YAML syntax'
    end
  end
end
