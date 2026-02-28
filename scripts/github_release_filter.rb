# frozen_string_literal: true

# GithubReleaseFilter detects non-stable GitHub release URLs.
# A release is considered unstable when its URL contains a pre-release
# identifier such as alpha, pre, nightly, or collab-.
class GithubReleaseFilter
  GITHUB_URL_PREFIX = 'https://github.com/'
  UNSTABLE_PATTERN = /alpha|pre|nightly|collab-/i

  def unstable?(url)
    str = url.to_s
    return false unless str.start_with?(GITHUB_URL_PREFIX)

    UNSTABLE_PATTERN.match?(str)
  end
end
