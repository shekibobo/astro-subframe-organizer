# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer run', type: :aruba do
  context 'with no options' do
    let!(:command) { run_command 'astro-subframe-organizer run' }

    it 'exits successfully' do
      type '8'
      stop_all_commands
      expect(last_command_started).to have_output an_output_string_including 'What are we organizing?'
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context 'with --config option' do
    let(:custom_config) { '~/astro-subframe-organizer/custom.yml' }

    before do
      write_file(custom_config, { 'telescopes' => ['RedCat51'] }.to_yaml)
      run_command "astro-subframe-organizer run --config #{custom_config}"
    end

    it 'exits successfully' do
      puts ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG']

      type '8'
      stop_all_commands
      expect(last_command_started).to have_output an_output_string_including "Using config file at #{custom_config}"
    end
  end
end
