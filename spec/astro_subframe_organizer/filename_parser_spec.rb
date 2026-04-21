# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe FilenameParsers do
    describe 'lights' do
      it 'parses metadata from light fits files' do
        path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        parser = FitsParser.new(path)
        result = parser.parse

        expect(result).to include(
          type: 'Light',
          target: 'M42',
          exposure: '1.0s',
          bin: '1',
          camera: 'T7',
          iso: '100',
          created_at: DateTime.new(2022, 5, 8, 12, 0, 0),
          ccd_temp: '-10.0C',
          image_index: '0001',
          file_format: :fits,
        )
      end

      it 'parses metadata from light raw files' do
        path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
        parser = CR2Parser.new(path)
        result = parser.parse

        expect(result).to include(
          type: 'Light',
          target: 'M42',
          file_format: :cr2,
        )
      end
    end

    describe 'darks' do
      it 'parses metadata from dark fits files' do
        path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        parser = FitsParser.new(path)
        result = parser.parse

        expect(result).to include(
          type: 'Dark',
          exposure: '30.0s',
          image_index: '0001',
        )
      end
    end

    describe 'factory .for_file()' do
      it 'with fits file, creates a FitsParser' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit'
        parser = FilenameParser.for_file(path)

        expect(parser).to be_instance_of(FitsParser)
      end

      it 'with raw file, creates CR2Parser' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
        parser = FilenameParser.for_file(path)

        expect(parser).to be_instance_of(CR2Parser)
      end

      it 'handles uppercase extensions' do
        path = '/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.FIT'
        parser = FilenameParser.for_file(path)

        expect(parser).to be_instance_of(FitsParser)
      end
    end
  end
end
