# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer bias', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  # bias-blanks: two distinct sets
  # Set 1: Bias_250.0us_Bin1_ISO800_YYYYMMDD_TEMP_NNNN.fit — T7/DSLR style, 100 frames, 2022-09-16
  #         temps vary 36.0C-38.0C (warm, daytime — DSLR uncooled)
  # Set 2: Bias_32.0us_Bin1_183MC_gain111_YYYYMMDD_-10.0C_NNNN.fit — cooled ASI style, 100 frames, 2022-12-29
  # Biases grouped by iso/gain, camera, and exposure time — these two sets will produce different dirs

  def copy_bias_fixtures(set:, count: 3)
    pattern = case set
              when :iso  then File.join(FIXTURE_ROOT, 'fits/bias-blanks', 'Bias_250.0us_*.fit')
              when :gain then File.join(FIXTURE_ROOT, 'fits/bias-blanks', 'Bias_32.0us_*.fit')
              end
    Dir.glob(pattern).sort.first(count).each do |f|
      FileUtils.cp(f, File.join(test_path, File.basename(f)))
    end
  end

  context 'with no FITS files present' do
    before { run_command_and_stop "astro-subframe-organizer bias --path #{test_path} --skip-confirm" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with ISO-based bias frames (250us, T7/DSLR style)' do
    before do
      copy_bias_fixtures(set: :iso, count: 3)
      run_command_and_stop "astro-subframe-organizer bias --path #{test_path} --camera T7 --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Bias_250.0us_Bin1_ISO800_20220916-150458_36.0C_0001.fit')
      expect(File).not_to exist(original)
    end
  end

  context 'with gain-based bias frames (32us, 183MC cooled style)' do
    before do
      copy_bias_fixtures(set: :gain, count: 3)
      run_command_and_stop "astro-subframe-organizer bias --path #{test_path} --camera 183MC --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'moves files into a subdirectory' do
      original = File.join(test_path, 'Bias_32.0us_Bin1_183MC_gain111_20221229-094956_-10.0C_0001.fit')
      expect(File).not_to exist(original)
    end
  end

  context 'with both bias sets mixed in one directory', :anounce do
    before do
      copy_bias_fixtures(set: :iso, count: 2)
      copy_bias_fixtures(set: :gain, count: 2)
      run_command_and_stop "astro-subframe-organizer bias --path #{test_path} --skip-confirm"
    end

    it 'creates separate subdirectories for each camera/exposure combination' do
      subdirs = Dir.glob(File.join(test_path, '*/'))
      expect(subdirs.size).to eq(2)
    end
  end

  context 'with --dry-run' do
    before do
      copy_bias_fixtures(set: :gain, count: 2)
      run_command_and_stop "astro-subframe-organizer bias --path #{test_path} --dry-run --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      original = File.join(test_path, 'Bias_32.0us_Bin1_183MC_gain111_20221229-094956_-10.0C_0001.fit')
      expect(File).to exist(original)
    end
  end

  context 'when detected camera is not in the configured list' do
    let(:custom_config) { File.join(test_path, 'limited_config.yml') }

    before do
      File.write(
        custom_config,
        {
          'cameras' => ['T7'],
          'telescopes' => ['RedCat51'],
          'filters' => ['NoFilter'],
        }.to_yaml,
      )
      copy_bias_fixtures(set: :gain, count: 1)
      run_command(
        "astro-subframe-organizer bias --path #{test_path} --config #{custom_config} --skip-confirm",
      )
    end

    it 'logs a warning and prompts for confirmation' do
      expect(last_command_started).to have_output(/INSTRUME header 'ZWO ASI183MC Pro' is not in the configured camera list/)
      expect(last_command_started).to have_output(/select the actual camera or confirm/)
    end
  end
end
