# frozen_string_literal: true

class FeedSource
  FeedEntry = Data.define :title, :url, :published_at, :feed_name, :summary do
    def initialize(title:, url:, published_at:, feed_name:, summary: nil)
      super
    end

    def to_fusion_entry
      base = title.to_s.strip
      base = '(no title)' if base.empty?
      FusionRss::FeedEntry.new \
        title: "[#{feed_name}] #{base}",
        url: url,
        published_at: published_at,
        feed_name: feed_name,
        summary: summary
    end

    def url_blank?
      url.to_s.strip.empty?
    end
  end
end
