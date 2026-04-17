# frozen_string_literal: true

require_relative '../../test_helper'

class TestTelescope < AstroSubframeOrganizer::Test
  # Tests for Telescope class
  def test_all_telescopes
    assert_includes Telescope.all, 'RedCat51'
    assert_includes Telescope.all, 'ZhumellZ130'
    assert_includes Telescope.all, 'AperturaAD8'
    assert_includes Telescope.all, 'MeadeDS90'
    assert_includes Telescope.all, 'CanonEFS1855'
  end
end
