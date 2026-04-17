# frozen_string_literal: true

require_relative '../../test_helper'

class TestFilter < AstroSubframeOrganizer::Test
  # Tests for Filter class
  def test_all_filters
    assert_includes Filter.all, 'BaaderMoon'
    assert_includes Filter.all, 'NBZ'
    assert_includes Filter.all, 'NoFilter'
  end
end
