# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe PathBuilder do
    it 'builds correct path for dark frames' do
      photo = Astrophoto.new('/fake/Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to eq('Dark_ISO_100_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_T7_MONTH_2022-05')
    end

    it 'builds correct path for flat frames' do
      photo = Astrophoto.new('/fake/Flat_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to match(/^Flat_FLATSET_/)
      expect(target_dir).to match(/TELESCOPE_RedCat51/)
    end

    it 'builds correct path for light frames' do
      photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to match(/^Light_M42/)
    end
    it 'builds correct path for bias frames' do
      photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to match(/^Bias_ISO_100/)
    end
    it 'builds target path that includes filename' do
      photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_path = PathBuilder.target_path_for(photo)

      expect(target_path).to match(%r{Light_M42_.*/Light_M42_1\.0s_Bin1_T7_ISO100_20220508-120000_-10\.0C_0001\.fit$})
    end
    it 'raises error for unsupported type' do
      photo = Astrophoto.new('/fake/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      photo.type = 'Unknown'

      expect { PathBuilder.build_for(photo) }.to raise_error(ArgumentError)
    end
    it 'builds correct path for flat dark frames' do
      photo = Astrophoto.new('/fake/Dark_5.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
      photo.dark_flat = true

      target_dir = PathBuilder.target_path_for(photo)

      expect(target_dir).to match(/^DarkFlat_FLATSET_/)
      expect(target_dir).to match(/ISO_100/)
    end
  end
end
