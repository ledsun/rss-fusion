# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../scripts/github_release_filter'

class GithubReleaseFilterTest < Minitest::Test
  def setup
    @filter = GithubReleaseFilter.new
  end

  # --- stable releases (should return false) ---

  def test_stable_semver_is_not_unstable
    refute @filter.unstable?('https://github.com/owner/repo/releases/tag/v1.2.3')
  end

  def test_stable_semver_without_v_prefix_is_not_unstable
    refute @filter.unstable?('https://github.com/owner/repo/releases/tag/1.2.3')
  end

  def test_stable_with_package_prefix_is_not_unstable
    refute @filter.unstable?('https://github.com/owner/repo/releases/tag/rust-v1.2.3')
  end

  def test_non_github_url_is_not_unstable
    refute @filter.unstable?('https://example.com/releases/tag/nightly')
  end

  def test_empty_string_is_not_unstable
    refute @filter.unstable?('')
  end

  def test_nil_is_not_unstable
    refute @filter.unstable?(nil)
  end

  # --- unstable: alpha ---

  def test_alpha_tag_is_unstable
    assert @filter.unstable?('https://github.com/openai/codex/releases/tag/rust-v0.105.0-alpha.17')
  end

  def test_alpha_tag_without_prefix_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/v1.0.0-alpha.1')
  end

  # --- unstable: beta ---

  def test_beta_tag_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/v2.0.0-beta.3')
  end

  # --- unstable: rc ---

  def test_rc_tag_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/v1.0.0-rc.1')
  end

  def test_rc_tag_without_dot_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/v1.0.0-rc1')
  end

  # --- unstable: pre ---

  def test_pre_tag_is_unstable
    assert @filter.unstable?('https://github.com/zed-industries/zed/releases/tag/v0.226.0-pre')
  end

  # --- unstable: nightly ---

  def test_nightly_tag_is_unstable
    assert @filter.unstable?('https://github.com/zed-industries/zed/releases/tag/nightly')
  end

  def test_nightly_with_suffix_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/nightly-20231204')
  end

  # --- unstable: dev ---

  def test_dev_tag_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/v1.0.0-dev.1')
  end

  # --- unstable: snapshot ---

  def test_snapshot_tag_is_unstable
    assert @filter.unstable?('https://github.com/owner/repo/releases/tag/1.0.0-snapshot')
  end
end
