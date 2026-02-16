# frozen_string_literal: true

require "test_helper"

class TestObjenealogist < Minitest::Test
  def test_to_tree
    expected = /C Objenealogist \(location: .*objenealogist.rb:7\)/

    assert_match expected, Objenealogist.to_tree(Objenealogist)
  end
end
