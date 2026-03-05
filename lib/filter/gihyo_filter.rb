# frozen_string_literal: true

class Filter
  # Filters gihyo.jp feed entries, passing only those whose title or summary
  # contains at least one AI/tech keyword of interest.
  class GihyoFilter
    GIHYO_URL_PREFIX = 'https://gihyo.jp/'
    KEYWORDS = /OpenAPI|ChatGPT|Claude|Gemini|MCP|Llama|Qwen3|Codex/i

    # Returns true if the entry should be excluded.
    def reject?(entry)
      return false unless entry.url.to_s.start_with?(GIHYO_URL_PREFIX)

      !KEYWORDS.match?(entry.title.to_s) && !KEYWORDS.match?(entry.summary.to_s)
    end
  end
end
