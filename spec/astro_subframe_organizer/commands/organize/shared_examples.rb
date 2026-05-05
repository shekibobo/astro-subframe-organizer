# frozen_string_literal: true

require 'spec_helper'

# FITS file fixtures needed in spec/fixtures/fits/:
#
# light_single.fit  - A single light frame FITS file. IMAGETYP='Light Frame',
#                     OBJECT present, INSTRUME matches a known camera, TELESCOP
#                     matches a known telescope, FILTER matches a known filter,
#                     EXPOSURE >= 1.0. Used to verify a full organize run.
#
# dark_single.fit   - A single dark frame FITS file. IMAGETYP='Dark Frame',
#                     INSTRUME matches a known camera, EXPOSURE >= 1.0,
#                     CCD-TEMP present. No TELESCOP or FILTER needed.
#
# flat_single.fit   - A single flat frame FITS file. IMAGETYP='Flat Frame',
#                     INSTRUME matches a known camera, TELESCOP matches a known
#                     telescope, FILTER matches a known filter.
#
# bias_single.fit   - A single bias frame FITS file. IMAGETYP='Bias Frame',
#                     INSTRUME matches a known camera. Exposure is typically 0.
#
# All fixtures should have DATE-OBS present in ISO 8601 format.
shared_examples 'an organize command' do |command:, type:|
  let(:test_path)    { aruba.config.home_directory }
  let(:fixture_file) { "#{type}_single.fit" }
  let(:fixture_src)  { File.join(FIXTURE_DIR, fixture_file) }

  def copy_fixture(filename)
    # TODO: Remove this guard once fixture files are in place
    skip "Fixture #{filename} not found — add a sample FITS file at spec/fixtures/fits/#{filename}" unless File.exist?(File.join(FIXTURE_DIR, filename))
    FileUtils.cp(File.join(FIXTURE_DIR, filename), File.join(test_path, filename))
  end

  context 'with no FITS files present' do
    before { run_command_and_stop "astro-subframe-organizer #{command}" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with a sample FITS file' do
    before do
      copy_fixture(fixture_file)
      run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path}"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --dry-run' do
    before do
      copy_fixture(fixture_file)
      run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --dry-run"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not move any files' do
      expect(File).to exist(File.join(test_path, fixture_file))
    end
  end

  context 'with --verbose' do
    before do
      copy_fixture(fixture_file)
      run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --verbose"
    end

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
          'cameras' => ['T7'],
          'filters' => ['NoFilter'],
        }.to_yaml,
      )
      copy_fixture(fixture_file)
      run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --config #{custom_config}"
    end

    it 'exits successfully' do
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context 'with --config pointing to a nonexistent file' do
    before do
      run_command "astro-subframe-organizer #{command} --path #{test_path} --config /nonexistent/config.yml"
      stop_all_commands
    end

    it 'exits with a non-zero status' do
      expect(last_command_started).not_to have_exit_status(0)
    end
  end
end

shared_examples 'an organize command with equipment options' do |command:|
  let(:test_path) { aruba.config.home_directory }

  context 'with --telescope' do
    before { run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --telescope RedCat51" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --camera' do
    before { run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --camera T7" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with --filter' do
    before do
      run_command_and_stop "astro-subframe-organizer #{command} --path #{test_path} --filter NoFilter"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end
  end

  context 'with all equipment options' do
    before do
      run_command(
        "astro-subframe-organizer #{command} --path #{test_path} " \
        '--telescope RedCat51 --camera T7 --filter NoFilter',
      )
      type 'y'
      stop_all_commands
    end

    it 'exits successfully' do
      expect(last_command_started).to have_exit_status(0)
    end
  end
end
