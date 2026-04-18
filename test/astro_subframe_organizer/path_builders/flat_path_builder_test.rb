# frozen_string_literal: true

require_relative '../../test_helper'

class TestFlatPathBuilder < AstroSubframeOrganizer::Test
  def test_builds_flat_path
    photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    builder = FlatPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Flat_FLATSET_/, target_dir)
    assert_match(/ISO_100/, target_dir)
    assert_match(/EXP_1\.0s/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
    assert_match(/FILTER_BaaderMoon/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
  end
end
