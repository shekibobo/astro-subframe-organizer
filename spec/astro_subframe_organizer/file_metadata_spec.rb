# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  include FilenameParsers

  describe FileMetadata do
    it 'parses metadata from filename' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse

      metadata = FileMetadata.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        type: 'Light',
        target: 'M42',
        exposure: '1.0s',
        bin: '1',
        camera: 'T7',
        iso: '100',
        gain: nil,
      )
    end

    it 'correctly identifies file format' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
      parser = CR2FilenameParser.new(path)
      parsed_data = parser.parse
      metadata = FileMetadata.from_parsed_data(parsed_data)

      expect(metadata.file_format).to equal(:cr2)
    end

    it 'includes path and filename' do
      path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse
      metadata = FileMetadata.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        path: path,
        filename: 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit',
      )
    end

    it 'can parse camera and gain' do
      path = '/fake/path/Light_M42_1.0s_Bin1_183MC_gain100_20220508-120000_-10.0C_0001.fit'
      parser = FitsFilenameParser.new(path)
      parsed_data = parser.parse
      metadata = FileMetadata.from_parsed_data(parsed_data)

      expect(metadata).to have_attributes(
        camera: '183MC',
        gain: '100',
        iso: nil,
      )
    end
  end
end
