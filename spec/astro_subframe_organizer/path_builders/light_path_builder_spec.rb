# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe LightPathBuilder do
      describe 'fits files' do
        it 'builds a target directory path including matching keywords for Light frames' do
          photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = LightPathBuilder.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M42_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
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
        it 'builds a target directory path including matching keywords for Light frames and pane keyword' do
          photo = Astrophoto.new('/fake/Light_M42_1-2_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
          photo.telescope = 'RedCat51'
          photo.filter = 'BaaderMoon'
          builder = LightPathBuilder.new(photo)

          target_dir = builder.build

          expect(target_dir).to eq('Light_M42_PANE_1-2_FLATSET_20220509_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
          # assert_match(/^Light_M42_PANE_1-2/, target_dir)
          # assert_match(/TELESCOPE_RedCat51/, target_dir)
        end
      end
    end
  end
end
