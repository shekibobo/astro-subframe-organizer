# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe FlatPathBuilder do
      it 'builds a target directory path including matching keywords for Dark frames' do
        photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        photo.telescope = 'RedCat51'
        photo.filter = 'BaaderMoon'
        builder = FlatPathBuilder.new(photo)

        target_dir = builder.build

        expect(target_dir).to eq('Flat_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
      end
    end
  end
end
