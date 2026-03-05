# frozen_string_literal: true

# Filter combines BlackList, GithubReleaseFilter, and GihyoFilter into a single filter.
# FusionRss calls match? once per entry; counts for each category are
# tracked internally and exposed via blacklisted_count / unstable_count.
class Filter
  attr_reader :blacklisted_count, :unstable_count

  def initialize(blacklist)
    @blacklist = blacklist
    @github_release_filter = GithubReleaseFilter.new
    @gihyo_filter = GihyoFilter.new
    @blacklisted_count = 0
    @unstable_count = 0
  end

  def match?(entry)
    url = entry.url.to_s
    if @blacklist.match? url
      @blacklisted_count += 1
      true
    elsif @github_release_filter.unstable? url
      @unstable_count += 1
      true
    elsif @gihyo_filter.reject? entry
      true
    else
      false
    end
  end
end
