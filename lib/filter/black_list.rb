# frozen_string_literal: true

class Filter
  # Loads URL prefix rules from a file and checks URLs against them.
  class BlackList
    def initialize(path)
      @rules = load_blacklist(path)
    end

    def length
      @rules.length
    end

    def match?(url)
      @rules.any? { |rule| url.start_with?(rule) }
    end

    private

    def load_blacklist(path)
      return [] unless File.exist?(path)

      File.readlines(path, chomp: true).filter_map do |line|
        rule = line.strip
        next if rule.empty? || rule.start_with?('#')

        rule
      end
    end
  end
end
