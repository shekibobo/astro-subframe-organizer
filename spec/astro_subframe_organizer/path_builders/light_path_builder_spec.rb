# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe LightPathBuilder, :files do
      describe 'fits files' do
        let(:path) { fixture('fits/C1-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-235753_288deg_-10.0C_0010.fit') }
        it 'builds a target directory path including matching keywords for Light frames' do
          photo = FilenameParsers::FitsFilenameParser.new(path).parse
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = LightPathBuilder.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_C 1_FLATSET_20260411_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_183MC')
        end
      end

      describe 'raw files' do
        it 'builds a target directory path including matching keywords for Light frames' do
          photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = LightPathBuilder.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
          # assert_match(/^Light_M42/, target_dir)
          # assert_match(/CCD-TEMP_-10\./, target_dir)
          # assert_match(/TELESCOPE_RedCat51/, target_dir)
          # assert_match(/FILTER_BaaderMoon/, target_dir)
        end
      end

      describe 'mosaics' do
        let(:path) { fixture('fits/mosaic-blanks/Light_M16_1-1_300.0s_Bin1_183MC_gain0_20240713-022314_-10.0C_0003.fit') }

        it 'builds a target directory path including matching keywords for Light frames and pane keyword' do
          parser = FilenameParsers::FitsHeaderParser.new(path)
          photo = parser.parse
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = LightPathBuilder.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M16_PANE_1-1_FLATSET_20240713_GAIN_0_EXP_300.0_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_ZWO ASI183MC Pro')
        end
      end
    end
  end
end
