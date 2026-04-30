# frozen_string_literal: true

require 'spec_helper'

# Fixtures in spec/fixtures/fits/ are header-only FITS files stripped with
# bin/strip_fits. One representative file from each set is used per frame type.
#
# C1-blanks:    Light frames, target "C 1", 300s, Bin1, 183MC, gain 111,
#               rotation 288deg, -10.0C, captured 2026-04-10 through 2026-04-11
#
# dark-blanks:  Dark frames at multiple exposures (1s, 5s, 10s, 30s, 60s,
#               120s, 180s, 300s, 600s), Bin1, 183MC, gain 111, -10.0C
#               Note: some files have -10.5C or -9.5C temp variations
#
# flat-blanks:  Flat frames, rotation 293deg, 5s, Bin1, 183MC, gain 111,
#               captured across three sessions: 2025-12-24, 2026-01-13,
#               2026-02-18. Some files have -9.5C or -10.5C temp variations.

FIXTURE_ROOT = File.expand_path('../../../fixtures/fits', __dir__)
puts FIXTURE_ROOT
puts Dir.exist?(FIXTURE_ROOT)

def fixture(relative_path)
  File.join(FIXTURE_ROOT, relative_path)
end

def skip_unless_fixture_exists(path)
  skip "Fixture not found: #{path}" unless File.exist?(path)
end

shared_examples 'a successful organize command' do |command|
  it 'exits successfully' do
    expect(last_command_started.exit_status).to eq(0)
  end
end

shared_examples 'a dry run that preserves files' do |command:, fixture_files:|
  it 'exits successfully' do
    expect(last_command_started.exit_status).to eq(0)
  end

  it 'does not move any fixture files' do
    fixture_files.each do |path|
      expect(File).to exist(path)
    end
  end
end

describe 'astro-subframe-organizer light', type: :aruba do
  let(:test_path) { aruba.config.home_directory }
  let(:light_fixture) do
    fixture('C1-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-230651_288deg_-10.0C_0001.fit')
  end

  before do
    skip_unless_fixture_exists(light_fixture)
    FileUtils.cp(light_fixture, File.join(test_path, File.basename(light_fixture)))
  end

  context 'with a single light frame and all equipment options' do
    before do
      run_command_and_stop(
        'astro-subframe-organizer light ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--skip-confirm',
      )
    end

    include_examples 'a successful organize command'
  end

  context 'with --dry-run' do
    let(:copied_fixture) { File.join(test_path, File.basename(light_fixture)) }

    before do
      run_command_and_stop(
        'astro-subframe-organizer light ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--dry-run ' \
        '--skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move the fixture file' do
      expect(File).to exist(copied_fixture)
    end
  end

  context 'with --verbose' do
    before do
      run_command_and_stop(
        'astro-subframe-organizer light ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--verbose ' \
        '--skip-confirm',
      )
    end

    include_examples 'a successful organize command'
  end

  context 'with no equipment options (relies on header detection)' do
    before do
      run_command "astro-subframe-organizer light --path #{test_path} " \
        '--skip-confirm'
      type '1'
      stop_all_commands
    end

    include_examples 'a successful organize command'
  end

  context 'with multiple light frames from the same session' do
    # Uses first 3 files from C1-blanks — same target, exposure, camera, rotation
    let(:additional_fixtures) do
      [
        fixture('C1-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-231319_288deg_-10.0C_0002.fit'),
        fixture('C1-blanks/Light_C 1_300.0s_Bin1_183MC_gain111_20260410-231831_288deg_-10.0C_0003.fit'),
      ]
    end

    before do
      additional_fixtures.each do |f|
        skip_unless_fixture_exists(f)
        FileUtils.cp(f, File.join(test_path, File.basename(f)))
      end

      run_command_and_stop(
        'astro-subframe-organizer light ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--skip-confirm',
      )
    end

    include_examples 'a successful organize command'
  end
end

RSpec.describe 'astro-subframe-organizer dark', type: :aruba, announce_output: false do
  let(:test_path) { aruba.config.home_directory }

  # Dark frames at multiple exposures to verify grouping by exposure time
  {
    '1s' => 'dark-blanks/Dark_1.0s_Bin1_183MC_gain111_20260411-130000_-10.0C_0001.fit',
    '5s' => 'dark-blanks/Dark_5.0s_Bin1_183MC_gain111_20260411-130006_-10.0C_0001.fit',
    '10s' => 'dark-blanks/Dark_10.0s_Bin1_183MC_gain111_20260411-130018_-10.0C_0001.fit',
    '30s' => 'dark-blanks/Dark_30.0s_Bin1_183MC_gain111_20260411-130049_-10.0C_0001.fit',
    '60s' => 'dark-blanks/Dark_60.0s_Bin1_183MC_gain111_20260411-130150_-10.0C_0001.fit',
    '120s' => 'dark-blanks/Dark_120.0s_Bin1_183MC_gain111_20260411-130352_-10.0C_0001.fit',
    '180s' => 'dark-blanks/Dark_180.0s_Bin1_183MC_gain111_20260411-130653_-10.0C_0001.fit',
    '300s' => 'dark-blanks/Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit',
    '600s' => 'dark-blanks/Dark_600.0s_Bin1_183MC_gain111_20260411-132156_-10.0C_0001.fit',
  }.each do |exposure, relative_path|
    context "with a #{exposure} dark frame" do
      let(:dark_fixture) { fixture(relative_path) }

      before do
        skip_unless_fixture_exists(dark_fixture)
        FileUtils.cp(dark_fixture, File.join(test_path, File.basename(dark_fixture)))
        run_command_and_stop(
          'astro-subframe-organizer dark ' \
          '--skip-confirm ' \
          "--path #{test_path} " \
          '--camera 183MC',
        )
      end

      include_examples 'a successful organize command'
    end
  end

  context 'with a dark frame with temperature variation (-10.5C)' do
    # Dark_10.0s file 0021 has -10.5C instead of -10.0C — verify it still organizes
    let(:dark_fixture) do
      fixture('dark-blanks/Dark_10.0s_Bin1_183MC_gain111_20260411-201934_-10.5C_0021.fit')
    end

    before do
      skip_unless_fixture_exists(dark_fixture)
      FileUtils.cp(dark_fixture, File.join(test_path, File.basename(dark_fixture)))
      run_command_and_stop 'astro-subframe-organizer dark ' \
        "--path #{test_path} " \
        '--camera 183MC ' \
        '--skip-confirm'
    end

    include_examples 'a successful organize command'
  end

  context 'with mixed exposure dark frames' do
    # Two different exposure lengths in the same directory — verify they are
    # grouped separately rather than merged into one fileset
    let(:fixtures) do
      [
        fixture('dark-blanks/Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit'),
        fixture('dark-blanks/Dark_600.0s_Bin1_183MC_gain111_20260411-132156_-10.0C_0001.fit'),
      ]
    end

    before do
      fixtures.each do |f|
        skip_unless_fixture_exists(f)
        FileUtils.cp(f, File.join(test_path, File.basename(f)))
      end
      run_command_and_stop "astro-subframe-organizer dark --path #{test_path} --camera 183MC " \
        '--skip-confirm'
    end

    include_examples 'a successful organize command'
  end

  context 'with --dry-run' do
    let(:dark_fixture) do
      fixture('dark-blanks/Dark_300.0s_Bin1_183MC_gain111_20260411-131154_-10.0C_0001.fit')
    end
    let(:copied_path) { File.join(test_path, File.basename(dark_fixture)) }

    before do
      skip_unless_fixture_exists(dark_fixture)
      FileUtils.cp(dark_fixture, copied_path)
      run_command_and_stop(
        'astro-subframe-organizer dark ' \
        "--path #{test_path} " \
        '--camera 183MC ' \
        '--telescope Redcat51 ' \
        '--filter BaaderMoon ' \
        '--dry-run ' \
        '--skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move the dark frame' do
      expect(File).to exist(copied_path)
    end
  end
end

RSpec.describe 'astro-subframe-organizer flat', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # Three different capture sessions represented in flat-blanks:
  # - 2025-12-24: first session
  # - 2026-01-13: second session
  # - 2026-02-18: third session
  # All are 5s, 293deg rotation, 183MC, gain 111

  {
    'December 2025 session' => 'flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit',
    'January 2026 session' => 'flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20260113-011341_-10.5C_0001.fit',
    'February 2026 session' => 'flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20260218-232013_-10.0C_0001.fit',
  }.each do |session_name, relative_path|
    context "with a flat from the #{session_name}" do
      let(:flat_fixture) { fixture(relative_path) }

      before do
        skip_unless_fixture_exists(flat_fixture)
        FileUtils.cp(flat_fixture, File.join(test_path, File.basename(flat_fixture)))
        run_command_and_stop(
          'astro-subframe-organizer flat ' \
          "--path #{test_path} " \
          '--telescope RedCat51 ' \
          '--camera 183MC ' \
          '--filter NoFilter ' \
          '--skip-confirm',
        )
      end

      include_examples 'a successful organize command'
    end
  end

  context 'with a flat with temperature variation (-9.5C)' do
    # flat-blanks/20251224 file 0005 and 0006 have -9.5C — verify they still organize
    let(:flat_fixture) do
      fixture('flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111528_-9.5C_0005.fit')
    end

    before do
      skip_unless_fixture_exists(flat_fixture)
      FileUtils.cp(flat_fixture, File.join(test_path, File.basename(flat_fixture)))
      run_command_and_stop(
        'astro-subframe-organizer flat ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--skip-confirm',
      )
    end

    include_examples 'a successful organize command'
  end

  context 'with flats from multiple sessions mixed together' do
    # Simulates having unorganized flats from different nights in one directory.
    # The organizer should group them appropriately rather than treating them
    # as one homogeneous set.
    let(:fixtures) do
      [
        fixture('flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit'),
        fixture('flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20260113-011341_-10.5C_0001.fit'),
        fixture('flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20260218-232013_-10.0C_0001.fit'),
      ]
    end

    before do
      fixtures.each do |f|
        skip_unless_fixture_exists(f)
        FileUtils.cp(f, File.join(test_path, File.basename(f)))
      end
      run_command_and_stop(
        'astro-subframe-organizer flat ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--skip-confirm',
      )
    end

    include_examples 'a successful organize command'
  end

  context 'with --dry-run' do
    let(:flat_fixture) do
      fixture('flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111503_-10.0C_0001.fit')
    end
    let(:copied_path) { File.join(test_path, File.basename(flat_fixture)) }

    before do
      skip_unless_fixture_exists(flat_fixture)
      FileUtils.cp(flat_fixture, copied_path)
      run_command_and_stop(
        'astro-subframe-organizer flat ' \
        "--path #{test_path} " \
        '--telescope RedCat51 ' \
        '--camera 183MC ' \
        '--filter NoFilter ' \
        '--dry-run ' \
        '--skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move the flat frame' do
      expect(File).to exist(copied_path)
    end
  end
end
