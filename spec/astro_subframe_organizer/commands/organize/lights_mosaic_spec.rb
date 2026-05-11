# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer light (mosaic)', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # mosaic-blanks: Light_M16_1-1_300.0s_Bin1_183MC_gain0_YYYYMMDD-HHMMSS_-10.0C_NNNN.fit
  # Three nights: 2024-07-01 (1 frame), 2024-07-11 (6 frames, indices 1,3-7),
  #               2024-07-13 (7 frames, indices 1-5,7-8)
  # Note: indices are non-sequential across nights — FileSet will split on index reset
  # Pane 1-1 in the filename — mosaic_pane parsed from filename since ASIAIR omits it from headers

  def copy_mosaic_fixtures(date_prefix:, count: 3)
    pattern = File.join(FIXTURE_ROOT, 'fits/mosaic-blanks', "Light_M16_1-1_300.0s_Bin1_183MC_gain0_#{date_prefix}*.fit")
    Dir.glob(pattern).sort.first(count).each do |f|
      FileUtils.cp(f, File.join(test_path, File.basename(f)))
    end
  end

  context 'with a single mosaic frame' do
    before do
      copy_mosaic_fixtures(date_prefix: '20240701', count: 1)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with frames from a single mosaic night (2024-07-13)' do
    before do
      copy_mosaic_fixtures(date_prefix: '20240713', count: 5)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Light_M16_1-1_300.0s_Bin1_183MC_gain0_20240713-021238_-10.0C_0001.fit')
      expect(File).not_to exist(original)
    end
  end

  context 'with frames from multiple mosaic nights' do
    before do
      copy_mosaic_fixtures(date_prefix: '20240711', count: 3)
      copy_mosaic_fixtures(date_prefix: '20240713', count: 3)
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
      copy_mosaic_fixtures(date_prefix: '20240713', count: 2)
      run_command_and_stop(
        "astro-subframe-organizer light --path #{test_path} " \
        '--telescope RedCat51 --camera 183MC --filter NoFilter --dry-run --skip-confirm',
      )
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      original = File.join(test_path, 'Light_M16_1-1_300.0s_Bin1_183MC_gain0_20240713-021238_-10.0C_0001.fit')
      expect(File).to exist(original)
    end
  end
end
