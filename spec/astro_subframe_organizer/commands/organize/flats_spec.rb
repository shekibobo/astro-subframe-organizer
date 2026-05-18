# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer flat', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # flat-blanks: three sessions — 2025-12-24, 2026-01-13, 2026-02-18
  # All 5.0s, 293deg rotation, 183MC, gain111
  # Some frames have -9.5C or -10.5C temp variations
  # Flats grouped by FLATSET date, rotation, equipment
  # FILTER absent (OSC), TELESCOP is mount name — both must be passed via CLI

  def copy_flat_fixtures(date_prefix:, count: 3)
    pattern = File.join(FIXTURE_ROOT, 'fits/flat-blanks', "Flat_293deg_5.0s_Bin1_183MC_gain111_#{date_prefix}*.fit")
    Dir.glob(pattern).first(count).each do |f|
      FileUtils.cp(f, File.join(test_path, File.basename(f)))
    end
  end

  context 'with no FITS files present' do
    before { run_command_and_stop "astro-subframe-organizer flat --path #{test_path} --skip-confirm" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with flats from the December 2025 session' do
    before do
      copy_flat_fixtures(date_prefix: '20251224')
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit')
      expect(File).not_to exist(original)
    end
  end

  context 'with flats from the January 2026 session' do
    before do
      copy_flat_fixtures(date_prefix: '20260113')
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with flats from the February 2026 session' do
    before do
      copy_flat_fixtures(date_prefix: '20260218')
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with flats from multiple sessions mixed in one directory' do
    # Simulates having unorganized flats from three different nights together.
    # Each session should produce its own FLATSET subdirectory.
    before do
      copy_flat_fixtures(date_prefix: '20251224', count: 2)
      copy_flat_fixtures(date_prefix: '20260113', count: 2)
      copy_flat_fixtures(date_prefix: '20260218', count: 2)
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'creates a separate subdirectory for each session' do
      subdirs = Dir.glob(File.join(test_path, '*/'))
      expect(subdirs.size).to eq(3)
    end
  end

  context 'with a flat with temperature variation (-9.5C)' do
    before do
      path = File.join(
        FIXTURE_ROOT,
        'fits',
        'flat-blanks',
        'Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111528_-9.5C_0005.fit',
      )
      FileUtils.cp(path, File.join(test_path, File.basename(path)))
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --dry-run' do
    before do
      copy_flat_fixtures(date_prefix: '20251224', count: 2)
      run_command_and_stop(
        "astro-subframe-organizer flat --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --dry-run --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      original = File.join(test_path, 'Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit')
      expect(File).to exist(original)
    end
  end
end
