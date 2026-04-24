# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer rename-from-exif', :skip, type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # Expects: IMG_0001.CR2 in spec/fixtures/cr2/ — a standard unprocessed
  #          Canon CR2 with ExposureTime >= 1.0s and a known camera model.
  def copy_fixture(fixture_name)
    src  = File.expand_path('../../fixtures/cr2', __dir__)
    dest = File.join(test_path, fixture_name)
    FileUtils.cp(File.join(src, fixture_name), dest)
  end

  context 'with a dark frame' do
    before do
      copy_fixture('IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer rename-from-exif --type Dark --path #{test_path}"
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
      copy_fixture('IMG_0001.CR2')
      run_command_and_stop(
        "astro-subframe-organizer rename-from-exif --type Light --target M31 --path #{test_path}",
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
      copy_fixture('IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer rename-from-exif --type Light --path #{test_path}"
    end

    it 'exits with a non-zero status' do
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'outputs an error message' do
      expect(last_command_started.output).to include('--target is required for light frames')
    end
  end

  context 'with already-renamed files' do
    before do
      FileUtils.touch(File.join(test_path, 'Dark_300.0s_Bin1_T7_ISO800_20240101T120000_-10.0C_0001.CR2'))
      run_command_and_stop "astro-subframe-organizer rename-from-exif --type Dark --path #{test_path}"
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
      copy_fixture('IMG_0001.CR2')
      run_command_and_stop "astro-subframe-organizer rename-from-exif --type Dark --dry-run --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not rename the file' do
      expect(File).to exist(File.join(test_path, 'IMG_0001.CR2'))
    end
  end
end
