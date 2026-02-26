# frozen_string_literal: true

require 'net/http'
require 'uri'

# SubscribeRss represents a feed source and provides HTTP fetching.
class SubscribeRss
  USER_AGENT = 'rss-merge-bot/0.1'
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 20
  MAX_REDIRECTS = 3

  attr_reader :name, :url

  def initialize(name:, url:)
    @name = name
    @url = url
  end

  def http_get(target_url = url, limit: MAX_REDIRECTS)
    raise "Too many redirects while fetching #{target_url}" if limit.negative?

    uri = URI.parse(target_url)
    raise "Unsupported URL scheme for #{target_url}" unless %w[http https].include?(uri.scheme)

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENT

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      response.body.to_s
    when Net::HTTPRedirection
      location = response['location']
      raise "Redirect response without Location for #{target_url}" if location.to_s.strip.empty?

      redirected = URI.join(target_url, location).to_s
      http_get(redirected, limit: limit - 1)
    else
      raise "HTTP #{response.code} #{response.message} for #{target_url}"
    end
  end
end
