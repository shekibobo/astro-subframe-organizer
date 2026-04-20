# frozen_string_literal: true

require 'test_helper'

class ExeAstroSubframeOrganizerTest < AstroSubframeOrganizer::Test
  include Aruba::Api

  def setup
    super
    setup_aruba
    prepend_environment_variable 'PATH', "#{File.expand_path('../../exe', __dir__)}#{File::PATH_SEPARATOR}"
  end

  def test_correct_binary
    run_command_and_stop 'which astro-subframe-organizer'
    assert_includes last_command_started.output, 'exe/astro-subframe-organizer'
  end

  def test_cli_init_command
    run_command_and_stop 'printenv HOME'
    assert_includes last_command_started.output, 'tmp/aruba'

    assert !file?('~/.astro-subframe-organizer.yml'), 'Expected config file to not exist at ~/.astro-subframe-organizer.yml'
    run_command_and_stop 'which astro-subframe-organizer'
    assert_includes last_command_started.output, 'exe/astro-subframe-organizer'
    run_command_and_stop 'astro-subframe-organizer --init'
    assert_includes last_command_started.output, 'Created default config file at ~/.astro-subframe-organizer.yml'
    assert_includes last_command_started.output, 'Edit this file to customize your telescopes, filters, and cameras.'
    assert file?('~/.astro-subframe-organizer.yml'), 'Expected config file to be created at ~/.astro-subframe-organizer.yml'
  end

  def test_cli_help_command
    run_command_and_stop 'astro-subframe-organizer --help'
    assert_includes last_command_started.output, 'Usage: astro-subframe-organizer [options]'
    assert_includes last_command_started.output, '--config FILE'
    assert_includes last_command_started.output, '--init'
    assert_includes last_command_started.output, '-h, --help'
  end
end
