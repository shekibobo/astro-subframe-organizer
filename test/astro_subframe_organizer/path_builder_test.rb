# frozen_string_literal: true

require_relative '../test_helper'

class TestPathBuilder < Minitest::Test
  def test_build_for_dark_returns_dark_path
    photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

    target_dir = AstroSubframeOrganizer::PathBuilder.build_for(photo)

    assert_match(/^Dark_ISO_100/, target_dir)
  end

  def test_build_for_flat_returns_flat_path
    photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_dir = AstroSubframeOrganizer::PathBuilder.build_for(photo)

    assert_match(/^Flat_FLATSET_/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
  end

  def test_build_for_light_returns_light_path
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_dir = AstroSubframeOrganizer::PathBuilder.build_for(photo)

    assert_match(/^Light_M42/, target_dir)
  end

  def test_build_for_bias_returns_bias_path
    photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

    target_dir = AstroSubframeOrganizer::PathBuilder.build_for(photo)

    assert_match(/^Bias_ISO_100/, target_dir)
  end

  def test_target_path_for_includes_filename
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_path = AstroSubframeOrganizer::PathBuilder.target_path_for(photo)

    assert_match %r{Light_M42_.*/Light_M42_1\.0s_Bin1_T7_ISO100_20220508-120000_-10\.0C_0001\.fit$}, target_path
  end

  def test_build_for_raises_on_unsupported_type
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.type = 'Unknown'

    assert_raises(ArgumentError) do
      AstroSubframeOrganizer::PathBuilder.build_for(photo)
    end
  end
end
