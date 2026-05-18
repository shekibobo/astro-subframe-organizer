# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

describe 'astro-subframe-organizer init', type: :aruba do
  let(:config_path) { File.join(aruba.config.home_directory, 'astro-subframe-organizer-config.yml') }
  let(:custom_config_path) { File.join(aruba.config.home_directory, 'custom.yml') }

  let(:config) { YAML.load_file(config_path) }
  let(:custom_config) { YAML.load_file(custom_config_path) }

  let(:simple_config) { { 'temperature_tolerance' => '5.0' } }

  context 'with no config option' do
    let(:command) { 'astro-subframe-organizer init' }

    context 'no config file exists yet' do
      before { run_command_and_stop command }

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
        it 'includes telescopes' do
          expect(config['telescopes']).to include('RedCat51', 'ZhumellZ130')
        end

        it 'includes filters' do
          expect(config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
        end

        it 'includes cameras' do
          expect(config['cameras']).to include('Canon EOS 1500D', 'ZWO ASI183MC Pro')
        end
      end
    end

    context 'when file already exists' do
      before do
        File.write(config_path, simple_config.to_yaml)
        run_command_and_stop command
      end

      it 'exits successfully' do
        expect(last_command_started.exit_status).to eq(0)
      end

      it 'does not overwrite the existing file' do
        expect(File).to exist(config_path)
        expect(config).not_to include('cameras', 'telescopes', 'filters')
      end

      it 'outputs a confirmation message' do
        expect(last_command_started.output).to include("Config file #{config_path} already exists. Use --force to overwrite anyway.")
      end

      it 'outputs an instruction to edit the file' do
        expect(last_command_started.output).to include('Edit this file to customize')
      end

      context 'with --force option' do
        let(:command) { 'astro-subframe-organizer init --force' }

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
          it 'includes telescopes' do
            expect(config['telescopes']).to include('RedCat51', 'ZhumellZ130')
          end

          it 'includes filters' do
            expect(config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
          end

          it 'includes cameras' do
            expect(config['cameras']).to include('Canon EOS 1500D', 'ZWO ASI183MC Pro')
          end
        end
      end
    end
  end

  context 'with --config option' do
    let(:command) { "astro-subframe-organizer init --config #{custom_config_path}" }

    context 'when no config file exists' do
      before { run_command_and_stop command }

      it 'exits successfully' do
        expect(last_command_started.exit_status).to eq(0)
      end

      it 'creates the config file in the home directory' do
        expect(File).to exist(custom_config_path)
      end

      it 'outputs a confirmation message' do
        expect(last_command_started.output).to include('Created config file')
      end

      it 'outputs an instruction to edit the file' do
        expect(last_command_started.output).to include('Edit this file to customize')
      end

      describe 'the created config file' do
        it 'includes telescopes' do
          expect(custom_config['telescopes']).to include('RedCat51', 'ZhumellZ130')
        end

        it 'includes filters' do
          expect(custom_config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
        end

        it 'includes cameras' do
          expect(custom_config['cameras']).to include('Canon EOS 1500D', 'ZWO ASI183MC Pro')
        end
      end
    end

    context 'when file already exists' do
      before do
        File.write(custom_config_path, simple_config.to_yaml)
        run_command_and_stop command
      end

      it 'exits successfully' do
        expect(last_command_started.exit_status).to eq(0)
      end

      it 'does not overwrite the existing file' do
        expect(File).to exist(custom_config_path)
        expect(custom_config).not_to include('cameras', 'telescopes', 'filters')
      end

      it 'outputs a confirmation message' do
        expect(last_command_started.output).to include("Config file #{custom_config_path} already exists. Use --force to overwrite anyway.")
      end

      it 'outputs an instruction to edit the file' do
        expect(last_command_started.output).to include('Edit this file to customize')
      end

      context 'with --force option' do
        let(:command) { "astro-subframe-organizer init --config #{custom_config_path} --force" }

        it 'exits successfully' do
          expect(last_command_started.exit_status).to eq(0)
        end

        it 'creates the config file in the home directory' do
          expect(File).to exist(custom_config_path)
        end

        it 'outputs a confirmation message' do
          expect(last_command_started.output).to include('Created config file')
        end

        it 'outputs an instruction to edit the file' do
          expect(last_command_started.output).to include('Edit this file to customize')
        end

        describe 'the created config file' do
          it 'includes telescopes' do
            expect(custom_config['telescopes']).to include('RedCat51', 'ZhumellZ130')
          end

          it 'includes filters' do
            expect(custom_config['filters']).to include('BaaderMoon', 'NBZ', 'NoFilter')
          end

          it 'includes cameras' do
            expect(custom_config['cameras']).to include('Canon EOS 1500D', 'ZWO ASI183MC Pro')
          end
        end
      end
    end

    context 'with specific equipment' do
      let(:command) do
        "astro-subframe-organizer init --config #{custom_config_path} --telescope ZhumellZ130 --filter BaaderMoon --camera 183MC"
      end

      before { run_command_and_stop command }

      it 'exits successfully' do
        expect(last_command_started.exit_status).to eq(0)
      end

      it 'creates the config file in the home directory' do
        expect(File).to exist(custom_config_path)
      end

      it 'outputs a confirmation message' do
        expect(last_command_started.output).to include('Created config file')
      end

      it 'outputs an instruction to edit the file' do
        expect(last_command_started.output).to include('Edit this file to customize')
      end

      describe 'the created config file' do
        it 'includes telescopes' do
          expect(custom_config['telescopes']).to contain_exactly('ZhumellZ130')
        end

        it 'includes filters' do
          expect(custom_config['filters']).to contain_exactly('BaaderMoon')
        end

        it 'includes cameras' do
          expect(custom_config['cameras']).to contain_exactly('183MC')
        end
      end
    end
  end
end
