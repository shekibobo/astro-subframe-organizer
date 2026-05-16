# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer raw rename', type: :aruba do
  let(:test_path) { expand_path('.') }

  context 'with a dark frame' do
    before do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file' do
      expect(Dir.glob('Dark_*.{CR2,cr2}', base: test_path)).not_to be_empty
    end
  end

  context 'with a light frame and target' do
    before do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
      run_command_and_stop(
        "astro-subframe-organizer raw rename --type Light --target M31 --path #{test_path}",
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'includes the target in the filename' do
      expect(Dir.glob('*M31*.{CR2,cr2}', base: test_path)).not_to be_empty
    end
  end

  context 'with a light frame and no target' do
    before do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
      run_command "astro-subframe-organizer raw rename --type Light --path #{test_path}"
    end

    it 'exits with a non-zero status' do
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'outputs an error message' do
      stop_all_commands
      expect(last_command_started.output).to include('--target is required for light frames')
    end
  end

  context 'with already-renamed files' do
    before do
      touch 'Dark_300.0s_Bin1_T7_ISO800_20240101-120000_-10.0C_0001.CR2'
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'outputs a warning' do
      expect(last_command_started.output).to include('already be renamed')
    end
  end

  context 'with --dry-run' do
    before do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --dry-run --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not rename the file' do
      expect('IMG_0001.CR2').to be_an_existing_file
    end
  end

  context 'with a file in a subdirectory' do
    let(:subdir_name) { 'subdirectory' }
    let(:subdir_path) { expand_path(subdir_name) }

    before do
      install_fixture('cr2/dark/IMG_0001.CR2', subdir_path, dest_path: 'IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file in place within its subdirectory' do
      expect(File.join(subdir_name, 'Dark_4.0s_Bin1_T7_ISO6400_20210418-025548_21.0C_0001.CR2')).to be_an_existing_file
    end

    it 'does not move the file to the root directory' do
      expect(Dir.glob('*.{CR2,cr2}', base: test_path)).to be_empty
    end

    it 'leaves the subdirectory intact' do
      expect(subdir_name).to be_an_existing_directory
    end
  end
end
