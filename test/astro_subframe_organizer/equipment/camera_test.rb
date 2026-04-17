# frozen_string_literal: true

require_relative '../../test_helper'

class TestCamera < AstroSubframeOrganizer::Test
  include Equipment

  # Tests for Camera class
  def test_all_cameras
    assert_includes Camera.all, 'T7'
    assert_includes Camera.all, '183MC'
  end
end
