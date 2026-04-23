# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'astro-subframe-organizer init', type: :aruba do
  let(:config_path) { File.join(aruba.config.home_directory, '.astro-subframe-organizer.yml') }
  let(:custom_config_path) { File.join(aruba.config.home_directory, 'custom.yml') }

  context 'with no config option' do
    before { run_command_and_stop 'astro-subframe-organizer init' }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'creates the config file in the home directory' do
      expect(File).to exist(config_path)
    end

    it 'outputs a confirmation message' do
      expect(last_command_started.output).to include('Created default config file')
    end

    it 'outputs an instruction to edit the file' do
      expect(last_command_started.output).to include('Edit this file to customize')
    end

    describe 'the created config file' do
      subject(:config) { YAML.load_file(config_path) }

      it 'includes telescopes' do
        expect(config['telescopes']).to include('RedCat51', 'ZhumellZ130')
      end

      it 'includes filters' do
        expect(config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
      end

      it 'includes cameras' do
        expect(config['cameras']).to include('T7', '183MC')
      end
    end
  end

  context 'with --config option' do
    before { run_command_and_stop "astro-subframe-organizer init --config #{custom_config_path}" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'creates the config file in the home directory' do
      expect(File).to exist(custom_config_path)
    end

    it 'outputs a confirmation message' do
      expect(last_command_started.output).to include('Created default config file')
    end

    it 'outputs an instruction to edit the file' do
      expect(last_command_started.output).to include('Edit this file to customize')
    end

    describe 'the created config file' do
      subject(:config) { YAML.load_file(custom_config_path) }

      it 'includes telescopes' do
        expect(config['telescopes']).to include('RedCat51', 'ZhumellZ130')
      end

      it 'includes filters' do
        expect(config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
      end

      it 'includes cameras' do
        expect(config['cameras']).to include('T7', '183MC')
      end
    end
  end
end
