# frozen_string_literal: true

require_relative '../../test_helper'

class TestTelescope < Minitest::Test
  include Equipment

  # Tests for Telescope class
  def test_all_telescopes
    assert_includes AstroSubframeOrganizer::Equipment::Telescope::ALL, 'RedCat51'
    assert_includes AstroSubframeOrganizer::Equipment::Telescope::ALL, 'ZhumellZ130'
    assert_includes AstroSubframeOrganizer::Equipment::Telescope::ALL, 'AperturaAD8'
    assert_includes AstroSubframeOrganizer::Equipment::Telescope::ALL, 'MeadeDS90'
    assert_includes AstroSubframeOrganizer::Equipment::Telescope::ALL, 'CanonEFS1855'
  end
end
