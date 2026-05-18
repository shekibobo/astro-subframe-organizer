# frozen_string_literal: true

module AstroSubframeOrganizer
  module FilenameParsers
    describe CR2FilenameParser do
      describe 'lights' do
        it 'parses metadata from light raw files' do
          path = '/fake/path/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2'
          parser = described_class.new(path)
          result = parser.parse

          expect(result).to have_attributes(
            type: 'Light',
            target: 'M42',
            file_format: :cr2,
          )
        end

        it 'initializes with already organized path (extracts telescope/filter)' do
          path = '/organized/Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.CR2'
          result = described_class.new(path).parse

          expect(result).to have_attributes(
            telescope: 'RedCat51',
            filter: 'BaaderMoon',
          )
        end
      end

      describe 'darks' do
        it 'parses metadata from dark fits files' do
          path = '/fake/path/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.CR2'
          parser = described_class.new(path)
          result = parser.parse

          expect(result).to have_attributes(
            type: 'Dark',
            exposure: '30.0s',
            image_index: '0001',
          )
        end
      end
    end
  end
end
