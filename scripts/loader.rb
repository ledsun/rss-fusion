# frozen_string_literal: true

require 'yaml'

class Loader
  class ConfigFormatError < StandardError; end

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
    unless row.is_a?(Hash)
      raise ConfigFormatError, "Invalid feed row: expected mapping (#{row.inspect})"
    end

    name = row['name'].to_s.strip
    url = row['url'].to_s.strip
    if name.empty? || url.empty?
      raise ConfigFormatError, "Invalid feed row: name and url are required (#{row.inspect})"
    end

    { name: name, url: url }
  end
end
