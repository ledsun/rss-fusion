# frozen_string_literal: true

require_relative 'filter/black_list'
require_relative 'filter/github_release_filter'

# Filter combines BlackList and GithubReleaseFilter into a single filter.
# FusionRss calls match? once per entry; counts for each category are
# tracked internally and exposed via blacklisted_count / unstable_count.
class Filter
  attr_reader :blacklisted_count, :unstable_count

  def initialize(blacklist)
    @blacklist = blacklist
    @github_release_filter = GithubReleaseFilter.new
    @blacklisted_count = 0
    @unstable_count = 0
  end

  def match?(url)
    if @blacklist.match?(url)
      @blacklisted_count += 1
      true
    elsif @github_release_filter.unstable?(url)
      @unstable_count += 1
      true
    else
      false
    end
  end
end
