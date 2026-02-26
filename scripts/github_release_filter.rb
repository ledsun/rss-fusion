# frozen_string_literal: true

# GithubReleaseFilter detects non-stable GitHub release URLs.
# A release is considered unstable when its tag contains a pre-release
# identifier such as alpha, beta, rc, pre, nightly, dev, or snapshot.
class GithubReleaseFilter
  GITHUB_RELEASE_URL_PATTERN = %r{\Ahttps://github\.com/[^/]+/[^/]+/releases/tag/(.+)\z}
  UNSTABLE_PATTERN = /(?:\A|[-_.])(?:alpha|beta|rc|pre|nightly|dev|snapshot)/i

  def unstable?(url)
    match = GITHUB_RELEASE_URL_PATTERN.match(url.to_s)
    return false unless match

    UNSTABLE_PATTERN.match?(match[1])
  end
end
