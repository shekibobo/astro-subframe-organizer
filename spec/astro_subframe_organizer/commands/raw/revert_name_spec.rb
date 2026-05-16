# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer raw revert', type: :aruba do
  let(:test_path) { expand_path('.') }

  context 'with a usefully named file' do
    before do
      install_fixture(
        'cr2/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
        test_path,
        dest_path: 'Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
      )
      run_command_and_stop "astro-subframe-organizer raw revert --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file' do
      expect('IMG_0441.CR2').to be_an_existing_file
    end
  end

  context 'with a file in a subdirectory' do
    let(:subdir_name) { 'Light_Aurora_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7' }
    let(:subdir_path) { expand_path(subdir_name) }

    before do
      install_fixture(
        'cr2/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
        subdir_path,
        dest_path: 'Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
      )
      run_command_and_stop "astro-subframe-organizer raw revert --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file in place within its subdirectory' do
      expect(File.join(subdir_name, 'IMG_0441.CR2')).to be_an_existing_file
    end

    it 'does not move the file to the root directory' do
      expect(Dir.glob('*.{CR2,cr2}', base: test_path)).to be_empty
    end

    it 'leaves the subdirectory intact' do
      expect(subdir_name).to be_an_existing_directory
    end
  end
end
