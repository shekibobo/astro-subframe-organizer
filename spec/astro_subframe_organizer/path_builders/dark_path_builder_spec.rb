# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe DarkPathBuilder do
      it 'builds a target directory path including matching keywords for Dark frames' do
        photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        builder = DarkPathBuilder.new(photo)

        target_dir = builder.build

        expect(target_dir).to eq('Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05')
      end

      it 'builds a target directory path including matching keywords for Flat-Dark frames' do
        photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        photo.dark_flat = true
        builder = DarkPathBuilder.new(photo)

        target_dir = builder.build

        expect(target_dir).to eq('DarkFlat_FLATSET_20220508_ISO_100_EXP_5.0s_Bin_1_CAMERA_T7')
      end
    end
  end
end
