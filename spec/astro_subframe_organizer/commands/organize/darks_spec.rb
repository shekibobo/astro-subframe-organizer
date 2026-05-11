# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer dark', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # dark-blanks: 9 exposure lengths (1s, 5s, 10s, 30s, 60s, 120s, 180s, 300s, 600s)
  # 30 frames each, all 183MC gain111, -10.0C (with occasional -10.5C or -9.5C variations)
  # All captured 2026-04-11 → grouped by MONTH_2026-04
  # Dark frames do NOT need telescope or filter options

  def copy_dark_fixtures(exposure:, count: 3)
    pattern = File.join(FIXTURE_ROOT, 'fits/dark-blanks', "Dark_#{exposure}s_*.fit")
    Dir.glob(pattern).sort.first(count).each do |f|
      FileUtils.cp(f, File.join(test_path, File.basename(f)))
    end
  end

  context 'with no FITS files present' do
    before { run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --skip-confirm" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --config pointing to a custom config file' do
    let(:custom_config) { File.join(test_path, 'custom.yml') }

    before do
      File.write(
        custom_config,
        {
          'telescopes' => ['RedCat51'],
          'cameras' => ['183MC'],
          'filters' => ['NoFilter'],
        }.to_yaml,
      )
      copy_dark_fixtures(exposure: '300.0', count: 1)
      run_command_and_stop(
        "astro-subframe-organizer dark --path #{test_path} " \
        "--config #{custom_config} --skip-confirm",
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --config pointing to a nonexistent file' do
    before do
      run_command_and_stop(
        "astro-subframe-organizer dark --path #{test_path} " \
        '--config /nonexistent/config.yml --skip-confirm',
        fail_on_error: false,
      )
    end

    it 'exits with a non-zero status' do
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'outputs an error message' do
      expect(last_command_started.output).to include('Unable to find')
    end
  end

  context 'with 300s dark frames' do
    before do
      copy_dark_fixtures(exposure: '300.0')
      run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit')
      expect(File).not_to exist(original)
    end

    it 'groups files into a single directory' do
      subdirs = Dir.glob(File.join(test_path, '*/'))
      expect(subdirs.size).to eq(1)
    end
  end

  # Each exposure length should produce a separate target directory since
  # darks are grouped by exposure time
  [['1.0', 1], ['5.0', 5], ['10.0', 10], ['300.0', 300], ['600.0', 600]].each do |exp, _|
    context "with #{exp}s dark frames" do
      before do
        copy_dark_fixtures(exposure: exp, count: 2)
        run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --skip-confirm"
      end

      it 'exits successfully' do
        expect(last_command_started.exit_status).to eq(0)
      end
    end
  end

  context 'with mixed exposure lengths in the same directory' do
    before do
      copy_dark_fixtures(exposure: '300.0', count: 2)
      copy_dark_fixtures(exposure: '600.0', count: 2)
      run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'creates separate subdirectories for each exposure length' do
      subdirs = Dir.glob(File.join(test_path, '*/'))
      expect(subdirs.size).to eq(2)
    end
  end

  context 'with a frame that has a temperature variation (-10.5C)' do
    # Dark_10.0s file 0021 has -10.5C — verify it organizes without error
    before do
      path = File.join(FIXTURE_ROOT, 'dark-blanks', 'Dark_10.0s_Bin1_183MC_gain111_20260411-201934_-10.5C_0021.fit')
      skip 'Fixture not found' unless File.exist?(path)
      FileUtils.cp(path, File.join(test_path, File.basename(path)))
      run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --dry-run' do
    before do
      copy_dark_fixtures(exposure: '300.0', count: 2)
      run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --dry-run --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      original = File.join(test_path, 'Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit')
      expect(File).to exist(original)
    end
  end
end
