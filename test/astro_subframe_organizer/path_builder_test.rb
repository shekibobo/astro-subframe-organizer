# frozen_string_literal: true

require_relative '../test_helper'

class TestPathBuilder < Minitest::Test
  def test_builds_dark_directory_path
    path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = AstroSubframeOrganizer::FitsParser.new(path)
    metadata = AstroSubframeOrganizer::FileMetadata.from_parsed_data(parser.parse)
    builder = AstroSubframeOrganizer::PathBuilder.new(metadata)

    target_dir = builder.target_dir

    assert_match(/^Dark_ISO_100_EXP_30\.0s/, target_dir)
    assert_match(/CCD-TEMP_-10\.0C/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
    assert_match(/MONTH_2022-05$/, target_dir)
  end

  def test_builds_light_fits_directory_path
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = AstroSubframeOrganizer::FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = AstroSubframeOrganizer::FileMetadata.from_parsed_data(parsed_data)
    builder = AstroSubframeOrganizer::PathBuilder.new(metadata)
    target_dir = builder.target_dir

    assert_match(/^Light_M42/, target_dir)
    assert_match(/TELESCOPE_RedCat51/, target_dir)
    assert_match(/FILTER_BaaderMoon/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
  end

  def test_builds_light_cr2_directory_path
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
    parser = AstroSubframeOrganizer::CR2Parser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = AstroSubframeOrganizer::FileMetadata.from_parsed_data(parsed_data)
    builder = AstroSubframeOrganizer::PathBuilder.new(metadata)
    target_dir = builder.target_dir

    assert_match(/^Light_M42/, target_dir)
    assert_match(/CCD-TEMP_-10\./, target_dir)
  end

  def test_builds_target_path_with_filename
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = AstroSubframeOrganizer::FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:telescope] = 'RedCat51'
    parsed_data[:filter] = 'BaaderMoon'

    metadata = AstroSubframeOrganizer::FileMetadata.from_parsed_data(parsed_data)
    builder = AstroSubframeOrganizer::PathBuilder.new(metadata)
    target_path = builder.target_path

    assert_match %r{Light_M42_.*/Light_M42_1\.0s_Bin1_T7_ISO100_20220508-120000_-10\.0C_0001\.fit$}, target_path
  end

  def test_builds_flat_dark_directory_path
    path = '/fake/path/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = AstroSubframeOrganizer::FitsParser.new(path)
    parsed_data = parser.parse
    parsed_data[:dark_flat] = true
    metadata = AstroSubframeOrganizer::FileMetadata.from_parsed_data(parsed_data)

    builder = AstroSubframeOrganizer::PathBuilder.new(metadata)
    target_dir = builder.target_dir

    assert_match(/^DarkFlat_FLATSET_/, target_dir)
    assert_match(/ISO_100/, target_dir)
  end
end
