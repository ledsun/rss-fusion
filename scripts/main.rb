#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'

FEEDS_PATH = 'feeds.yml'
BLACKLIST_PATH = 'blacklist.txt'
OUTPUT_DIR = 'public'
OUTPUT_PATH = File.join(OUTPUT_DIR, 'merged.xml')

MAX_ITEMS = 50

require_relative 'stats'
require_relative 'fusion_rss'
require_relative 'loader'
require_relative 'black_list'
require_relative 'subscribe_rss'

def log(msg)
  puts "[main] #{msg}"
end

def main
  loader = Loader.new(FEEDS_PATH)
  blacklist = BlackList.new(BLACKLIST_PATH)
  stats = Stats.new(feeds_total: loader.length)

  log "Loaded #{loader.length} feeds"
  log "Loaded #{blacklist.length} blacklist rules"

  fusion_rss = FusionRss.new(blacklist, MAX_ITEMS)

  loader.each do |subscribe_rss|
    entries = subscribe_rss.fetch_entries
    stats.feed_succeeded

    log "Fetched #{subscribe_rss.name} (#{subscribe_rss.url}) entries=#{entries.length}"

    entries.each do |entry|
      stats.item_fetched
      if entry.url.to_s.empty?
        stats.item_skipped_no_url
        next
      end

      fusion_rss.add(entry.to_fusion_entry)
    end
  rescue StandardError => e
    stats.feed_failed
    log "Feed fetch/parse failed: #{subscribe_rss.name} #{subscribe_rss.url} (#{e.class}: #{e.message})"
  end

  fusion_rss.finalize(stats)
  fusion_rss.write(OUTPUT_PATH)

  stats.summary.each { |line| log "Summary #{line}" }
  log "Wrote #{OUTPUT_PATH}"
rescue Loader::ConfigFormatError => e
  log "Feed config load failed: #{FEEDS_PATH} (#{e.class}: #{e.message})"
  raise
end

main
