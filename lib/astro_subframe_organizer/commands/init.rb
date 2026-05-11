# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    # Create default config file at ~/.astro-subframe-organizer.yml
    class Init < Dry::CLI::Command
      include SharedOptions

      desc 'Create default config file at ~/.astro-subframe-organizer.yml'

      option :force, type: :boolean, default: false, required: false, desc: 'Overwrite existing file'

      def call(force: false, **options)
        setup(**options.slice(:config, :verbose, :skip_confirm))

        config_file = options[:config] || File.join(ENV['HOME'], '.astro-subframe-organizer.yml')

        if File.exist?(config_file) && !force
          puts "Config file #{config_file} already exists. Use --force to overwrite anyway."
        else
          default_config = {
            'telescopes' => %w[
              RedCat51
              ZhumellZ130
              AperturaAD8
              MeadeDS90
              CanonEFS1855
            ],
            'filters' => %w[
              BaaderMoon
              NBZ
              NoFilter
            ],
            'cameras' => %w[
              T7
              183MC
            ],
            'temperature_tolerance' => 5.0,
          }
          require 'yaml'
          File.write(config_file, default_config.to_yaml)

          if options[:config]
            puts "Created config file at #{config_file}"
          else
            puts 'Created default config file at ~/.astro-subframe-organizer.yml'
          end
        end

        puts 'Edit this file to customize your telescopes, filters, and cameras.'
      end
    end
  end
end
