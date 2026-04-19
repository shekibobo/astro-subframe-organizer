# frozen_string_literal: true

require_relative '../../test_helper'

class TestFilter < AstroSubframeOrganizer::Test
  include Equipment

  # Tests for Filter class
  def test_all_filters
    assert_includes Filter::ALL, 'BaaderMoon'
    assert_includes Filter::ALL, 'NBZ'
    assert_includes Filter::ALL, 'NoFilter'
  end
end
