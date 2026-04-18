# frozen_string_literal: true

require_relative '../test_helper'

class TestTelescope < Minitest::Test
  # Tests for Telescope class
  def test_all_telescopes
    assert_includes Telescope::ALL, 'RedCat51'
    assert_includes Telescope::ALL, 'ZhumellZ130'
    assert_includes Telescope::ALL, 'AperturaAD8'
    assert_includes Telescope::ALL, 'MeadeDS90'
    assert_includes Telescope::ALL, 'CanonEFS1855'
  end
end
