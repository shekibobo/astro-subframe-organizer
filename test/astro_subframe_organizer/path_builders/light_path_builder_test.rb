# frozen_string_literal: true

require_relative '../../test_helper'

class TestLightPathBuilder < Minitest::Test
  def test_builds_light_fits_path
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    builder = AstroSubframeOrganizer::PathBuilders::LightPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Light_M42/, target_dir)
    assert_match(/FLATSET_/, target_dir)
    assert_match(/ISO_100/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
    assert_match(/FILTER_BaaderMoon/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
  end

  def test_builds_light_cr2_path
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    builder = AstroSubframeOrganizer::PathBuilders::LightPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Light_M42/, target_dir)
    assert_match(/CCD-TEMP_-10\./, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
    assert_match(/FILTER_BaaderMoon/, target_dir)
  end

  def test_builds_light_with_mosaic_pane
    photo = Astrophoto.new('/fake/Light_M42_1-2_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'
    builder = AstroSubframeOrganizer::PathBuilders::LightPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Light_M42_PANE_1-2/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
  end
end
