# frozen_string_literal: true

require 'open-uri'
require 'feedjira'
require 'time'

# FeedSource represents a feed source and provides HTTP fetching and parsing.
class FeedSource
  USER_AGENT = 'rss-merge-bot/0.1'
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 20
  CACHE_CONTROL = 'no-cache'

  attr_reader :name, :url

  def initialize(name:, url:)
    @name = name
    @url = url
  end

  def fetch_entries
    fetched_at = Time.now
    parsed = Feedjira.parse http_get
    raw = parsed.respond_to?(:entries) ? parsed.entries : nil
    (raw.is_a?(Array) ? raw : []).map do
      FeedEntry.new it, feed_name: name, fetched_at: fetched_at
    end
  end

  private

  def http_get
    # rubocop:disable Security/Open
    # open-uri is acceptable here because URLs are sourced from feeds.yml only.
    URI.open(
      url,
      'User-Agent' => USER_AGENT,
      'Cache-Control' => CACHE_CONTROL,
      'Pragma' => CACHE_CONTROL,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT,
      &:read
    )
    # rubocop:enable Security/Open
  end
end
