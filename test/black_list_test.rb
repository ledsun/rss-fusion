# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class BlackListTest < Minitest::Test
  def with_temp_blacklist_file(content)
    Dir.mktmpdir 'black-list-test-' do
      path = File.join it, 'blacklist.txt'
      File.write path, content
      yield path
    end
  end

  def test_read_from_loads_prefix_rules
    with_temp_blacklist_file "https://spam.example/\n# comment\n\nhttps://ads.example/\n" do
      black_list = Filter::BlackList.read_from it

      assert_equal 2, black_list.length
      assert black_list.match?('https://spam.example/post')
      assert black_list.match?('https://ads.example/banner')
      refute black_list.match?('https://good.example/')
    end
  end
end
