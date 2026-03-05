# frozen_string_literal: true

class Filter
  # Detects non-stable GitHub release URLs.
  # A release is considered unstable when its URL contains a pre-release
  # identifier such as alpha, pre, nightly, collab-, or rust-.
  class GithubReleaseFilter
    GITHUB_URL_PREFIX = 'https://github.com/'
    UNSTABLE_PATTERN = /alpha|pre|nightly|collab-|rust-/i

    def unstable?(url)
      str = url.to_s
      return false unless str.start_with? GITHUB_URL_PREFIX

      UNSTABLE_PATTERN.match? str
    end
  end
end
