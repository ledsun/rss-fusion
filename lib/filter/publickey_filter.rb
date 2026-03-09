# frozen_string_literal: true

class Filter
  # Filters publickey entries, passing only those tagged as AI-related.
  class PublickeyFilter
    PUBLICKEY_URL_PREFIX = 'https://www.publickey1.jp/'
    TARGET_CATEGORY = '機械学習・AI'

    def reject?(entry)
      return false unless entry.url.to_s.start_with? PUBLICKEY_URL_PREFIX

      !entry.categories.to_a.include?(TARGET_CATEGORY)
    end
  end
end
