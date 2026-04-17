# frozen_string_literal: true

require_relative '../test_helper'

class TestFileMetadata < AstroSubframeOrganizer::Test
  include FilenameParsers

  def test_creates_from_parser_result
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse

    metadata = FileMetadata.from_parsed_data(parsed_data)

    assert_equal 'Light', metadata.type
    assert_equal 'M42', metadata.target
    assert_equal '1.0s', metadata.exposure
    assert_equal '1', metadata.bin
    assert_equal 'T7', metadata.camera
    assert_equal '100', metadata.iso
    assert_nil metadata.gain
  end

  def test_metadata_is_frozen
    path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    metadata = FileMetadata.from_parsed_data(parsed_data)

    assert metadata.frozen?
  end

  def test_metadata_has_file_format
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
    parser = CR2Parser.new(path)
    parsed_data = parser.parse
    metadata = FileMetadata.from_parsed_data(parsed_data)

    assert_equal :cr2, metadata.file_format
  end

  def test_metadata_includes_path_and_filename
    path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    metadata = FileMetadata.from_parsed_data(parsed_data)

    assert_equal path, metadata.path
    assert_equal 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit', metadata.filename
  end

  def test_metadata_computed_properties_with_gain
    path = '/fake/path/Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit'
    parser = FitsParser.new(path)
    parsed_data = parser.parse
    metadata = FileMetadata.from_parsed_data(parsed_data)

    assert_equal '183MC', metadata.camera
    assert_equal '100', metadata.gain
    assert_nil metadata.iso
  end
end
