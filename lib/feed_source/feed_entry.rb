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
      candidates = []
      candidates << entry.url if entry.respond_to? :url
      candidates << entry.link if entry.respond_to? :link
      candidates << entry.links&.first if entry.respond_to? :links

      candidates.map { it.to_s.strip }.find { !it.empty? }
    end

    def extract_published_at(entry, fallback_time)
      value =
        if entry.respond_to?(:published) && entry.published
          entry.published
        elsif entry.respond_to?(:updated) && entry.updated
          entry.updated
        elsif entry.respond_to?(:last_modified) && entry.last_modified
          entry.last_modified
        elsif entry.respond_to?(:published_at) && entry.published_at
          entry.published_at
        end

      return fallback_time if value.nil?
      return value if value.is_a? Time

      Time.parse value.to_s
    rescue StandardError
      fallback_time
    end
  end
end
