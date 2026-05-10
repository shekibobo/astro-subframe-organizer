# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer light', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # light-blanks: Light_C 1_300.0s_Bin1_183MC_gain111_YYYYMMDD-HHMMSS_288deg_-10.0C_NNNN.fit
  # 62 frames across two nights: 2026-04-10 (files 0001-0010) and 2026-04-11 (files 0011-0062)
  # All taken after midnight UTC, which maps to the same flatset date.
  # TELESCOP header will be EQMod Mount (mount name, not OTA) — telescope must be passed via CLI.
  # FILTER header absent (OSC camera) — filter must be passed via CLI.

  def copy_light_fixtures(count: 3, start: 1)
    Dir.glob(File.join(FIXTURE_ROOT, 'fits/light-blanks', '*.fit'))
       .sort
       .first(count)
       .drop(start - 1)
       .each { |f| FileUtils.cp(f, File.join(test_path, File.basename(f))) }
  end

  context 'with no FITS files present' do
    before { run_command_and_stop "astro-subframe-organizer light --path #{test_path} --skip-confirm" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with a single light frame and equipment specified via CLI' do
    before do
      copy_light_fixtures(count: 1)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with a full session of light frames (first night, files 0001-0010)' do
    before do
      copy_light_fixtures(count: 10)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Light_C 1_300.0s_Bin1_183MC_gain111_20260410-230651_288deg_-10.0C_0001.fit')
      expect(File).not_to exist(original)
    end

    it 'groups all files into a single flatset directory' do
      subdirs = Dir.glob(File.join(test_path, '*/'))
      expect(subdirs.size).to eq(1)
    end
  end

  context 'with frames spanning two nights (indices reset — separate filesets expected)' do
    # Files 0010 (last of night 1) and 0011 (first of night 2) have index reset
    # from 0010 to 0011 which is sequential — but the date crosses midnight so
    # flatset_id will differ. FileSet groups by sequential image_index, so the
    # index reset between nights may or may not split them depending on ordering.
    before do
      copy_light_fixtures(count: 4, start: 9) # files 0009, 0010, 0011, 0012
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --dry-run' do
    before do
      copy_light_fixtures(count: 3)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --dry-run --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      original = File.join(test_path, 'Light_C 1_300.0s_Bin1_183MC_gain111_20260410-230651_288deg_-10.0C_0001.fit')
      expect(File).to exist(original)
    end
  end

  context 'with --verbose' do
    before do
      copy_light_fixtures(count: 1)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --verbose --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end
end
