# frozen_string_literal: true

class FeedSource
  # FeedEntry parses and wraps a single raw entry from a feed source.
  class FeedEntry
    attr_reader :title, :url, :published_at, :feed_name, :summary

    def initialize(entry, feed_name:, fetched_at:)
      @title = entry.respond_to?(:title) ? entry.title : nil
      @url = extract_url entry
      @published_at = extract_published_at entry, fetched_at
      @feed_name = feed_name
      @summary = entry.respond_to?(:summary) ? entry.summary : nil
    end

    def to_fusion_entry
      base = title.to_s.strip
      base = '(no title)' if base.empty?
      FusionRss::FeedEntry.new \
        title: "[#{feed_name}] #{base}",
        url:,
        published_at:,
        feed_name:,
        summary:
    end

    def url_blank?
      url.to_s.strip.empty?
    end

    private

    def extract_url(entry)
      %i[url link links].find do |method_name|
        next unless entry.respond_to? method_name

        candidate = entry.public_send method_name
        candidate = candidate&.first if method_name == :links
        candidate = candidate.to_s.strip
        break candidate unless candidate.empty?
      end
    end

    def extract_published_at(entry, fallback_time)
      value = %i[published updated last_modified published_at].find do |method_name|
        next unless entry.respond_to? method_name

        candidate = entry.public_send method_name
        break candidate if candidate
      end

      return fallback_time if value.nil?
      return value if value.is_a? Time

      Time.parse value.to_s
    rescue StandardError
      fallback_time
    end
  end
end
