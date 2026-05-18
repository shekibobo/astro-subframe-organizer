# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe LightPathBuilder, :files do
      describe 'fits files' do
        context 'without rotation headers' do
          let(:path) do
            fixture('fits/light-blanks/Light_IC 63_600.0s_Bin1_183MC_gain111_20251113-192818_-10.0C_0001.fit')
          end

          it 'builds a target directory path including matching keywords for Light frames' do
            photo = FilenameParser.for_file(path).parse
            photo.telescope = 'RedCat51'
            photo.filter = 'NBZ'
            builder = described_class.new(photo)

            target_dir = builder.build

            expect(target_dir).to eq('Light_IC 63_FLATSET_20251114_GAIN_111_EXP_600.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_NBZ_CAMERA_ZWO ASI183MC Pro')
          end
        end

        context 'with rotation headers' do
          let(:path) do
            fixture('fits/light-blanks/Light_NGC 2264_113deg_600.0s_Bin1_183MC_gain111_20260112-202400_-10.0C_0006.fit')
          end

          it 'builds a target directory path including matching keywords for Light frames' do
            photo = FilenameParser.for_file(path).parse
            photo.telescope = 'RedCat51'
            photo.filter = 'BaaderMoon'
            builder = described_class.new(photo)

            target_dir = builder.build

            expect(target_dir).to eq('Light_NGC 2264_FLATSET_20260113_ROTATION_113deg_GAIN_111_EXP_600.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_ZWO ASI183MC Pro')
          end
        end
      end

      describe 'raw files' do
        it 'builds a target directory path including matching keywords for Light frames' do
          photo = FilenameParser.for_file('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2').parse
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = described_class.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
        end
      end

      describe 'mosaics' do
        let(:path) do
          fixture('fits/mosaic-blanks/Light_M16_1-1_300.0s_Bin1_183MC_gain0_20240713-022314_-10.0C_0003.fit')
        end

        it 'builds a target directory path including matching keywords for Light frames and pane keyword' do
          parser = FilenameParsers::FitsHeaderParser.new(path)
          photo = parser.parse
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = described_class.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M16_PANE_1-1_FLATSET_20240713_GAIN_0_EXP_300.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_ZWO ASI183MC Pro')
        end
      end
    end
  end
end
