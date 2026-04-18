# frozen_string_literal: true

require_relative '../../test_helper'

class TestDarkPathBuilder < Minitest::Test
  def test_builds_normal_dark_path
    photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    builder = AstroSubframeOrganizer::PathBuilders::DarkPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Dark_ISO_100_EXP_30\.0s/, target_dir)
    assert_match(/CCD-TEMP_-10\.0C/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
    assert_match(/MONTH_2022-05$/, target_dir)
  end

  def test_builds_flat_dark_path
    photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.dark_flat = true
    builder = AstroSubframeOrganizer::PathBuilders::DarkPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^DarkFlat_FLATSET_/, target_dir)
    assert_match(/ISO_100/, target_dir)
    assert_match(/EXP_5\.0s/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
  end
end
