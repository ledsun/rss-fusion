# frozen_string_literal: true

require 'yaml'
require 'forwardable'

# FeedCatalog reads and validates feeds.yml and exposes feed rows via Enumerable.
class FeedCatalog
  extend Forwardable

  attr_reader :sources

  def_delegator :@sources, :length

  def self.read_from(path) = new path

  def initialize(path)
    data = YAML.load_file path
    feeds = data.is_a?(Hash) ? data['feeds'] : nil
    raise ConfigFormatError, 'Invalid feeds.yml: top-level \'feeds\' array is required' unless feeds.is_a? Array

    @sources = feeds.filter_map { build_item it }
  rescue Psych::SyntaxError => e
    raise ConfigFormatError, "Invalid feeds.yml YAML syntax: #{e.message}"
  end

  private

  def build_item(row)
    raise ConfigFormatError, "Invalid feed row: expected mapping (#{row.inspect})" unless row.is_a? Hash

    name = row['name'].to_s.strip
    url = row['url'].to_s.strip
    raise ConfigFormatError, "Invalid feed row: name and url are required (#{row.inspect})" if name.empty? || url.empty?

    FeedSource.new name:, url:
  end
end
