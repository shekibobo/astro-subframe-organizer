# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer raw revert', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  context 'with a usefully named file' do
    before do
      install_fixture(
        'cr2/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
        test_path,
        dest_path: 'Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2'
      )
      run_command_and_stop "astro-subframe-organizer raw revert --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file' do
      expect(Dir.glob('**/*.CR2', base: test_path).first).to eq('IMG_0441.CR2')
    end
  end

  context 'with a file in a subdirectory' do
    let(:subdir) do
      File.join(
        test_path,
        'Light_Aurora_FLATSET_20210418_ISO_6400_EXP_4.0s_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7',
      )
    end

    before do
      install_fixture(
        'cr2/Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2',
        subdir,
        dest_path: 'Light_Aurora_4.0s_Bin1_ISO6400_20210418-025606_20.0C_0441.CR2'
      )
      run_command_and_stop "astro-subframe-organizer raw revert --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file in place within its subdirectory' do
      expect(Dir.glob('**/*.CR2', base: subdir).first).to eq('IMG_0441.CR2')
    end

    it 'does not move the file to the root directory' do
      expect(Dir.glob('*.CR2', base: test_path)).to be_empty
    end

    it 'leaves the subdirectory intact' do
      expect(File).to exist(subdir)
    end
  end
end
