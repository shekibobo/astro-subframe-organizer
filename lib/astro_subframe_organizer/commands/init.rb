# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    # Create default config file at ~/astro-subframe-organizer-config.yml
    class Init < Dry::CLI::Command
      include SharedOptions
      include EquipmentOptions

      desc 'Create default config file at ~/astro-subframe-organizer-config.yml'
      # rubocop:disable Layout/LineLength
      example [
        '# Basic usage, creates default file with sample equipment',
        '--config ~/custom_config.yml # Creates a config file with sample equipment in custom file',
        '--config ~/galaxy-season.yml --telescope CarbonStar200 --filter BaaderMoon --camera 183MC # Creates a config file with sample equipment in custom file',
      ]
      # rubocop:enable Layout/LineLength

      option :force, type: :boolean, default: false, required: false, desc: 'Overwrite existing file'

      def call(force: false, **options)
        setup(**options.slice(:config, :verbose, :skip_confirm))

        config_file = options[:config] || File.join(Dir.home, 'astro-subframe-organizer-config.yml')

        if File.exist?(config_file) && !force
          puts "Config file #{config_file} already exists. Use --force to overwrite anyway."
        else
          require 'yaml'
          File.write(config_file, default_config(**options.slice(:telescope, :filter, :camera)).to_yaml)

          if options[:config]
            puts "Created config file at #{config_file}"
          else
            puts 'Created default config file at ~/astro-subframe-organizer-config.yml'
          end
        end

        puts 'Edit this file to customize your telescopes, filters, and cameras.'
      end

      def default_config(telescope: nil, filter: nil, camera: nil)
        {
          'telescopes' => telescope ? [telescope] : Config::DEFAULT_CONFIG.fetch('telescopes'),
          'filters' => filter ? [filter] : Config::DEFAULT_CONFIG.fetch('filters'),
          'cameras' => camera ? [camera] : Config::DEFAULT_CONFIG.fetch('cameras'),
          'temperature_tolerance' => 5.0,
        }
      end
    end
  end
end
