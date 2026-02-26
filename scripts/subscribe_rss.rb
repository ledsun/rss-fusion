# frozen_string_literal: true

require 'open-uri'

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

  def http_get(target_url = url)
    # rubocop:disable Security/Open
    # open-uri is acceptable here because URLs are sourced from feeds.yml only.
    URI.open(
      target_url,
      'User-Agent' => USER_AGENT,
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ).call(&:read)
    # rubocop:enable Security/Open
  end
end
