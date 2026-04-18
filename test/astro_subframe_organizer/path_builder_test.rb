# frozen_string_literal: true

require_relative '../test_helper'

class TestPathBuilder < AstroSubframeOrganizer::Test
  def test_build_for_dark_returns_dark_path
    photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

    target_dir = PathBuilder.build_for(photo)

    assert_match(/^Dark_ISO_100/, target_dir)
    assert_match(/^Dark_ISO_100_EXP_30\.0s/, target_dir)
    assert_match(/CCD-TEMP_-10\.0C/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
    assert_match(/MONTH_2022-05$/, target_dir)
  end

  def test_builds_dark_directory_path
    path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    metadata = FileMetadata.from_parsed_data(parser.parse)
    target_dir = PathBuilder.build_for(metadata)

    assert_match(/^Dark_ISO_100_EXP_30\.0s/, target_dir)
    assert_match(/CCD-TEMP_-10\.0C/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
    assert_match(/MONTH_2022-05$/, target_dir)
  end

  def test_build_for_flat_returns_flat_path
    photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_dir = PathBuilder.build_for(photo)

    assert_match(/^Flat_FLATSET_/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
  end

  def test_builds_flat_directory_path
    path = '/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse

    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = FileMetadata.from_parsed_data(parsed_data)

    target_dir = PathBuilder.build_for(metadata)

    assert_match(/^Flat_FLATSET_/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
  end

  def test_build_for_light_returns_light_path
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_dir = PathBuilder.build_for(photo)

    assert_match(/^Light_M42/, target_dir)
  end

  def test_builds_light_fits_directory_path
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = FileMetadata.from_parsed_data(parsed_data)
    target_dir = PathBuilder.target_path_for(metadata)

    assert_match(/^Light_M42/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
    assert_match(/FILTER_BaaderMoon/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
  end

  def test_builds_light_cr2_directory_path
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
    parser = CR2Parser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = FileMetadata.from_parsed_data(parsed_data)
    target_dir = PathBuilder.target_path_for(metadata)

    assert_match(/^Light_M42/, target_dir)
    assert_match(/CCD-TEMP_-10\./, target_dir)
  end

  def test_build_for_bias_returns_bias_path
    photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

    target_dir = PathBuilder.build_for(photo)

    assert_match(/^Bias_ISO_100/, target_dir)
  end

  def test_target_path_for_includes_filename
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.telescope = 'RedCat51'
    photo.filter = 'BaaderMoon'

    target_path = PathBuilder.target_path_for(photo)

    assert_match %r{Light_M42_.*/Light_M42_1\.0s_Bin1_T7_ISO100_20220508-120000_-10\.0C_0001\.fit$}, target_path
  end

  def test_build_for_raises_on_unsupported_type
    photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    photo.type = 'Unknown'

    assert_raises(ArgumentError) do
      PathBuilder.build_for(photo)
    end
  end

  def test_builds_target_path_with_filename
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = FileMetadata.from_parsed_data(parsed_data)
    target_path = PathBuilder.target_path_for(metadata)

    assert_match %r{Light_M42_.*/Light_M42_1\.0s_Bin1_T7_ISO100_20220508-120000_-10\.0C_0001\.fit$}, target_path
  end

  def test_builds_flat_dark_directory_path
    path = '/fake/path/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:dark_flat] = true

    metadata = FileMetadata.from_parsed_data(parsed_data)
    target_dir = PathBuilder.target_path_for(metadata)

    assert_match(/^DarkFlat_FLATSET_/, target_dir)
    assert_match(/ISO_100/, target_dir)
  end
end
