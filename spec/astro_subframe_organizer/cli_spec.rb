# frozen_string_literal: true

require 'spec_helper'

describe 'running astro-subframe-organizer', type: :aruba do
  describe 'aruba setup' do
    it 'uses the correct binary' do
      run_command_and_stop 'which astro-subframe-organizer'
      expect(last_command_started.output).to include('exe/astro-subframe-organizer')

      run_command_and_stop 'printenv HOME'
      expect(last_command_started.output).to include('tmp/aruba')

      run_command_and_stop 'which astro-subframe-organizer'
      expect(last_command_started.output).to include('exe/astro-subframe-organizer')
    end
  end

  it 'shows help with --help' do
    run_command_and_stop 'astro-subframe-organizer --help'
    expect(last_command_started.output).to include('Usage: astro-subframe-organizer [options]')
    expect(last_command_started.output).to include('--config FILE')
    expect(last_command_started.output).to include('--init')
    expect(last_command_started.output).to include('-h, --help')
  end

  describe '--init' do
    it 'creates default config file in home directory' do
      expect(file?('~/.astro-subframe-organizer.yml')).to be false

      run_command_and_stop 'astro-subframe-organizer --init'

      expect(last_command_started.output).to include('Created default config file at ~/.astro-subframe-organizer.yml')
      expect(last_command_started.output).to include('Edit this file to customize your telescopes, filters, and cameras.')

      expect(file?('~/.astro-subframe-organizer.yml')).to be true
    ensure
      remove('~/.astro-subframe-organizer.yml')
    end
  end

  describe 'with custom config', :files do
    let(:custom_config) { 'single_entry_config.yml' }
    let!(:custom_config_path) { install_fixture_file(fixture_path: custom_config) }

    it 'loads custom config file' do
      expect(file?(custom_config_path)).to be true
      run_command "astro-subframe-organizer --config #{custom_config_path}"

      stop_all_commands
      expect(last_command_started.output).to include("Using config file at #{custom_config_path}")
    end
  end
end
