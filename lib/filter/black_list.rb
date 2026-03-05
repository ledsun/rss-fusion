# frozen_string_literal: true

require 'forwardable'

class Filter
  # Loads URL prefix rules from a file and checks URLs against them.
  class BlackList
    extend Forwardable

    def_delegator :@rules, :length

    def self.read_from(path)
      new path
    end

    def initialize(path)
      @rules = load_blacklist path
    end

    def match?(url)
      @rules.any? { url.start_with? it }
    end

    private

    def load_blacklist(path)
      return [] unless File.exist? path

      File.readlines(path, chomp: true).filter_map do
        rule = it.strip
        next if rule.empty? || rule.start_with?('#')

        rule
      end
    end
  end
end
