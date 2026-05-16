# frozen_string_literal: true

require 'spec_helper'

describe 'Raw to Organized Workflow', type: :aruba do
  let(:test_path) { expand_path('.') }

  describe 'Darks Workflow' do
    it 'renames and organizes dark frames' do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')

      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
      expect(last_command_started).to have_exit_status(0)

      run_command_and_stop "astro-subframe-organizer darks --path #{test_path} --camera T7 --skip-confirm"
      expect(last_command_started).to have_exit_status(0)

      # Renamed: Dark_4.0s_Bin1_T7_ISO6400_20210418-025548_21.0C_0001.CR2
      # Organized: Dark_ISO_6400_EXP_4.0s_CCD-TEMP_20._CAMERA_T7_MONTH_2021-04/
      expected_dest = 'Dark_ISO_6400_EXP_4.0s_CCD-TEMP_20._CAMERA_T7_MONTH_2021-04/Dark_4.0s_Bin1_T7_ISO6400_20210418-025548_21.0C_0001.CR2'
      expect(expected_dest).to be_an_existing_file, "Found files:\n#{list('.').join("\n")}"
    end
  end

  describe 'Lights Workflow' do
    it 'renames and organizes light frames' do
      # Reusing dark fixture as it has valid EXIF for a test run
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')

      run_command_and_stop "astro-subframe-organizer raw rename --type Light --target M31 --path #{test_path}"
      expect(last_command_started).to have_exit_status(0)

      run_command_and_stop "astro-subframe-organizer lights --path #{test_path} --telescope RedCat51 --filter NoFilter --camera T7 --skip-confirm"
      expect(last_command_started).to have_exit_status(0)

      # Renamed: Light_M31_4.0s_Bin1_T7_ISO6400_20210418-025548_21.0C_0001.CR2
      # Organized: Light_M31_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_CCD-TEMP_20._TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7/
      expected_dest = 'Light_M31_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_CCD-TEMP_20._TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7/Light_M31_4.0s_Bin1_T7_ISO6400_20210418-025548_21.0C_0001.CR2'
      expect(expected_dest).to be_an_existing_file, "Found files:\n#{list('.').join("\n")}"
    end
  end

  describe 'Flats Workflow' do
    it 'renames and organizes flat frames' do
      install_fixture('cr2/flat/IMG_0002.CR2', test_path, dest_path: 'IMG_0002.CR2')

      run_command_and_stop "astro-subframe-organizer raw rename --type Flat --path #{test_path}"
      expect(last_command_started).to have_exit_status(0)

      run_command_and_stop "astro-subframe-organizer flats --path #{test_path} --telescope RedCat51 --filter NoFilter --camera T7 --skip-confirm"
      expect(last_command_started).to have_exit_status(0)

      # Based on fixture metadata:
      # Renamed: Flat_20.0ms_Bin1_T7_ISO200_20210523-213811_21.0C_0002.CR2
      # Organized: Flat_FLATSET_20210523_ISO_200_EXP_20.0ms_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7/
      expected_dest = 'Flat_FLATSET_20210523_ISO_200_EXP_20.0ms_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7/Flat_20.0ms_Bin1_T7_ISO200_20210523-213811_21.0C_0002.CR2'
      expect(expected_dest).to be_an_existing_file, "Found files:\n#{list('.').join("\n")}"
    end
  end

  describe 'Biases Workflow' do
    it 'renames and organizes bias frames' do
      install_fixture('cr2/bias/IMG_0003.CR2', test_path, dest_path: 'IMG_0003.CR2')

      run_command_and_stop "astro-subframe-organizer raw rename --type Bias --path #{test_path}"
      expect(last_command_started).to have_exit_status(0)

      run_command_and_stop "astro-subframe-organizer biases --path #{test_path} --camera T7 --skip-confirm"
      expect(last_command_started).to have_exit_status(0)

      # Based on fixture metadata:
      # Renamed: Bias_250.0us_Bin1_T7_ISO400_20210720-002402_22.0C_0003.CR2
      # Organized: Bias_ISO_400_EXP_250.0us_Bin_1_CAMERA_T7_MONTH_2021-07/
      expected_dest = 'Bias_ISO_400_EXP_250.0us_Bin_1_CAMERA_T7_MONTH_2021-07/Bias_250.0us_Bin1_T7_ISO400_20210720-002402_22.0C_0003.CR2'
      expect(expected_dest).to be_an_existing_file, "Found files:\n#{list('.').join("\n")}"
    end
  end
end
