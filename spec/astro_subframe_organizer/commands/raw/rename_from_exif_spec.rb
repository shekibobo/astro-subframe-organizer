# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer raw rename', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  context 'with a dark frame' do
    before do
      install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file' do
      expect(Dir.glob('*.CR2', base: test_path).first).to start_with('Dark_')
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
      expect(Dir.glob('*.CR2', base: test_path).first).to include('M31')
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
      FileUtils.touch(File.join(test_path, 'Dark_300.0s_Bin1_T7_ISO800_20240101T120000_-10.0C_0001.CR2'))
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
      expect(File).to exist(File.join(test_path, 'IMG_0001.CR2'))
    end
  end

  context 'with a file in a subdirectory' do
    let(:subdir) { File.join(test_path, 'subdirectory') }

    before do
      install_fixture('cr2/dark/IMG_0001.CR2', subdir, dest_path: 'IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer raw rename --type Dark --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'renames the file in place within its subdirectory' do
      expect(Dir.glob('*.CR2', base: subdir).first).to eq('Dark_4.0s_Bin1_T7_ISO6400_20210418T025548_21.0C_0001.CR2')
    end

    it 'does not move the file to the root directory' do
      expect(Dir.glob('*.CR2', base: test_path)).to be_empty
    end

    it 'leaves the subdirectory intact' do
      expect(File).to exist(subdir)
    end
  end
end
