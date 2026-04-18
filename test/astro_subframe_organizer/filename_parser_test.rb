# frozen_string_literal: true

require_relative '../test_helper'

class TestFilenameParser < AstroSubframeOrganizer::Test
  def test_fits_parser_light_file
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    result = parser.parse

    assert_equal 'Light', result[:type]
    assert_equal 'M42', result[:target]
    assert_equal '1.0s', result[:exposure]
    assert_equal '1', result[:bin]
    assert_equal 'T7', result[:camera]
    assert_equal '100', result[:iso]
    assert_equal DateTime.new(2022, 5, 8, 12, 0, 0), result[:created_at]
    assert_equal '-10.0C', result[:ccd_temp]
    assert_equal '0001', result[:image_index]
    assert_equal :fits, result[:file_format]
  end

  def test_fits_parser_dark_file
    path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    result = parser.parse

    assert_equal 'Dark', result[:type]
    assert_nil result[:target]
    assert_equal '30.0s', result[:exposure]
    assert_equal '0001', result[:image_index]
  end

  def test_cr2_parser_light_file
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
    parser = CR2Parser.new(path)
    result = parser.parse

    assert_equal 'Light', result[:type]
    assert_equal 'M42', result[:target]
    assert_equal :cr2, result[:file_format]
  end

  def test_filename_parser_factory_creates_fits_parser
    path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FilenameParser.for_file(path)

    assert_instance_of FitsParser, parser
  end

  def test_filename_parser_factory_creates_cr2_parser
    path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
    parser = FilenameParser.for_file(path)

    assert_instance_of CR2Parser, parser
  end

  def test_filename_parser_factory_handles_uppercase_extensions
    path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.FIT'
    parser = FilenameParser.for_file(path)

    assert_instance_of FitsParser, parser
  end
end
