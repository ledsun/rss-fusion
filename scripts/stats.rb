# frozen_string_literal: true

class Stats
  attr_reader :feeds_total, :feeds_succeeded, :feeds_failed,
              :items_fetched, :items_skipped_no_url, :items_skipped_blacklist,
              :items_skipped_duplicate, :items_output

  def initialize(feeds_total:)
    @feeds_total             = feeds_total
    @feeds_succeeded         = 0
    @feeds_failed            = 0
    @items_fetched           = 0
    @items_skipped_no_url    = 0
    @items_skipped_blacklist = 0
    @items_skipped_duplicate = 0
    @items_output            = 0
  end

  def feed_succeeded    = tap { @feeds_succeeded += 1 }
  def feed_failed       = tap { @feeds_failed += 1 }
  def item_fetched      = tap { @items_fetched += 1 }
  def item_skipped_no_url    = tap { @items_skipped_no_url += 1 }
  def item_skipped_blacklist = tap { @items_skipped_blacklist += 1 }
  def item_skipped_duplicate = tap { @items_skipped_duplicate += 1 }
  def finalize(output:, blacklisted:, duplicate:)
    tap do
      @items_skipped_blacklist += blacklisted
      @items_skipped_duplicate += duplicate
      @items_output = output
    end
  end

  def summary
    [
      "feeds total=#{feeds_total} success=#{feeds_succeeded} failed=#{feeds_failed}",
      "items fetched=#{items_fetched} skipped_no_url=#{items_skipped_no_url} skipped_blacklist=#{items_skipped_blacklist} skipped_duplicate=#{items_skipped_duplicate} output=#{items_output}"
    ]
  end
end