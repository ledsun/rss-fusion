# frozen_string_literal: true

require 'open-uri'
require 'feedjira'
require 'time'
require_relative 'fusion_rss/feed_entry'

# SubscribeRss represents a feed source and provides HTTP fetching and parsing.
class SubscribeRss
  FeedEntry = Data.define(:title, :url, :published_at, :feed_name) do
    def to_fusion_entry
      base = title.to_s.strip
      base = '(no title)' if base.empty?
      FusionRss::FeedEntry.new(
        title: "[#{feed_name}] #{base}",
        url: url,
        published_at: published_at,
        feed_name: feed_name
      )
    end
  end

  USER_AGENT = 'rss-merge-bot/0.1'
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 20

  attr_reader :name, :url

  def initialize(name:, url:)
    @name = name
    @url = url
  end

  def fetch_entries
    fetched_at = Time.now
    parsed = Feedjira.parse(http_get)
    raw = parsed.respond_to?(:entries) ? parsed.entries : nil
    (raw.is_a?(Array) ? raw : []).map do
      FeedEntry.new(
        title: it.respond_to?(:title) ? it.title : nil,
        url: extract_url(it),
        published_at: extract_published_at(it, fetched_at),
        feed_name: name
      )
    end
  end

  private

  def http_get
    # rubocop:disable Security/Open
    # open-uri is acceptable here because URLs are sourced from feeds.yml only.
    URI.open(
      url,
      'User-Agent' => USER_AGENT,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ).call(&:read)
    # rubocop:enable Security/Open
  end

  def extract_url(entry)
    candidates = []
    candidates << entry.url if entry.respond_to?(:url)
    candidates << entry.link if entry.respond_to?(:link)
    candidates << entry.links&.first if entry.respond_to?(:links)

    candidates.map { |v| v.to_s.strip }.find { |v| !v.empty? }
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
    return value if value.is_a?(Time)

    Time.parse(value.to_s)
  rescue StandardError
    fallback_time
  end
end
