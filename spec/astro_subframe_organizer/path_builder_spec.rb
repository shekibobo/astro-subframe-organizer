# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe PathBuilder, :files do
    it 'builds correct path for dark frames' do
      path = install_fixture(
        'fits/dark-blanks/Dark_30.0s_Bin1_183MC_gain111_20260411-204203_-10.0C_0022.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to eq('Dark_GAIN_111_EXP_30.0s_CCD-TEMP_-10.0C_CAMERA_ZWO ASI183MC Pro_MONTH_2026-04')
    end

    it 'builds correct path for flat frames' do
      path = install_fixture(
        'fits/flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111516_-10.0C_0003.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to match(/^Flat_FLATSET_/)
      expect(target_dir).to match(/TELESCOPE_RedCat51/)
    end

    it 'builds correct path for light frames' do
      path = install_fixture(
        'fits/light-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to match(/^Light_C 1_/)
    end

    it 'builds correct path for bias frames' do
      path = install_fixture(
        'fits/bias-blanks/Bias_32.0us_Bin1_183MC_gain111_20221229-095800_-10.0C_0093.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse

      target_dir = PathBuilder.build_for(photo)

      expect(target_dir).to eq('Bias_GAIN_111_EXP_32.0us_Bin_1_CAMERA_ZWO ASI183MC Pro_MONTH_2022-12')
    end

    it 'builds target path that includes filename' do
      path = install_fixture(
        'fits/light-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse
      photo.telescope = 'RedCat51'
      photo.filter = 'BaaderMoon'

      target_path = PathBuilder.target_path_for(photo)

      expect(target_path).to eq('Light_C 1_FLATSET_20260411_ROTATION_108deg_GAIN_111_EXP_300.0s_Bin_1_CCD-TEMP_-10._TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_ZWO ASI183MC Pro/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit')
    end

    it 'raises error for unsupported type' do
      path = install_fixture(
        'fits/light-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-233511_288deg_-10.0C_0006.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse
      photo.type = 'Unknown'

      expect { PathBuilder.build_for(photo) }.to raise_error(ArgumentError)
    end

    it 'builds correct path for flat dark frames' do
      path = install_fixture(
        'fits/dark-blanks/Dark_1.0s_Bin1_183MC_gain111_20260411-130000_-10.0C_0001.fit',
        test_dir,
      )
      photo = FilenameParser.for_file(path).parse
      photo.dark_flat = true

      target_dir = PathBuilder.target_path_for(photo)

      expect(target_dir).to eq('DarkFlat_FLATSET_20260411_GAIN_111_EXP_1.0s_Bin_1_CAMERA_ZWO ASI183MC Pro/Dark_1.0s_Bin1_183MC_gain111_20260411-130000_-10.0C_0001.fit')
    end
  end
end
