# frozen_string_literal: true

require 'yaml'
require_relative '../feed_source'
require_relative 'config_format_error'

# FeedCatalog reads and validates feeds.yml and exposes feed rows via Enumerable.
class FeedCatalog
  include Enumerable

  def initialize(path)
    data = YAML.load_file(path)
    feeds = data.is_a?(Hash) ? data['feeds'] : nil
    raise ConfigFormatError, 'Invalid feeds.yml: top-level \'feeds\' array is required' unless feeds.is_a?(Array)

    @items = feeds.filter_map { |row| build_item(row) }
  rescue Psych::SyntaxError => e
    raise ConfigFormatError, "Invalid feeds.yml YAML syntax: #{e.message}"
  end

  def each(&block)
    @items.each(&block)
  end

  def length
    @items.length
  end
  alias size length

  private

  def build_item(row)
    raise ConfigFormatError, "Invalid feed row: expected mapping (#{row.inspect})" unless row.is_a?(Hash)

    name = row['name'].to_s.strip
    url = row['url'].to_s.strip
    raise ConfigFormatError, "Invalid feed row: name and url are required (#{row.inspect})" if name.empty? || url.empty?

    FeedSource.new(name:, url:)
  end
end
