# frozen_string_literal: true

require 'open-uri'
require 'feedjira'

# SubscribeRss represents a feed source and provides HTTP fetching.
class SubscribeRss
  USER_AGENT = 'rss-merge-bot/0.1'
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 20

  attr_reader :name, :url

  def initialize(name:, url:)
    @name = name
    @url = url
  end

  def entries
    parsed = Feedjira.parse(http_get)
    raw = parsed.respond_to?(:entries) ? parsed.entries : nil
    raw.is_a?(Array) ? raw : []
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
end
