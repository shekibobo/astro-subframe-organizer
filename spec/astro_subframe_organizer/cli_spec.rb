# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'running astro-subframe-organizer', type: :aruba do
  before do
    setup_aruba
    prepend_environment_variable 'PATH', "#{File.expand_path('../../exe', __dir__)}#{File::PATH_SEPARATOR}"
  end

  it 'uses the correct binary' do
    run_command_and_stop 'which astro-subframe-organizer'
    expect(last_command_started.output).to include('exe/astro-subframe-organizer')
  end

  it 'creates default config file with --init' do
    run_command_and_stop 'printenv HOME'
    expect(last_command_started.output).to include('tmp/aruba')
    expect(file?('~/.astro-subframe-organizer.yml')).to be false
    run_command_and_stop 'which astro-subframe-organizer'
    expect(last_command_started.output).to include('exe/astro-subframe-organizer')
    run_command_and_stop 'astro-subframe-organizer --init'
    expect(last_command_started.output).to include('Created default config file at ~/.astro-subframe-organizer.yml')
    expect(last_command_started.output).to include('Edit this file to customize your telescopes, filters, and cameras.')
    expect(file?('~/.astro-subframe-organizer.yml')).to be true
  end

  it 'shows help with --help' do
    run_command_and_stop 'astro-subframe-organizer --help'
    expect(last_command_started.output).to include('Usage: astro-subframe-organizer [options]')
    expect(last_command_started.output).to include('--config FILE')
    expect(last_command_started.output).to include('--init')
    expect(last_command_started.output).to include('-h, --help')
  end

  it 'accepts custom config file with --config', :skip do
    custom_config_path = 'custom_config.yml'
    write_file(custom_config_path, "telescopes:\n  - CustomScope\nfilters:\n  - CustomFilter\ncameras:\n  - CustomCamera\n")
    run_command "astro-subframe-organizer --config #{custom_config_path}"
    expect(last_command_started.output).to include("Using config file at #{custom_config_path}")
    expect(last_command_started.output).to include('Using config file at')
    expect(last_command_started.output).to include(custom_config_path)
  ensure
    remove(custom_config_path) if exist?(custom_config_path)
  end
end
