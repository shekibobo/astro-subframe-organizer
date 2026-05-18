# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer unorganize', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  def create_organized_file(*path_parts)
    path = File.join(test_path, *path_parts)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
    path
  end

  context 'with no files' do
    before { run_command_and_stop "astro-subframe-organizer unorganize --path #{test_path}" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with organized FITS files' do
    before do
      create_organized_file(
        'Light_M42_FLATSET_20220508_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_183MC',
        'Light_M42_300.0s_Bin1_183MC_gain111_20220508-120000_-10.0C_0001.fit',
      )
      run_command_and_stop "astro-subframe-organizer unorganize --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves the file to the root directory' do
      expect(File).to exist(File.join(test_path, 'Light_M42_300.0s_Bin1_183MC_gain111_20220508-120000_-10.0C_0001.fit'))
    end

    it 'removes the subdirectory' do
      expect(Dir.glob(File.join(test_path, '*/'))).to be_empty
    end
  end

  context 'with --dry-run' do
    let!(:organized_file) do
      create_organized_file('SomeOrganizedDir', 'Light_M42_300.0s_0001.fit')
    end

    before { run_command_and_stop "astro-subframe-organizer unorganize --path #{test_path} --dry-run" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      expect(File).to exist(organized_file)
    end
  end
end
