# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Init < Dry::CLI::Command
      include SharedOptions

      desc 'Create default config file at ~/.astro-subframe-organizer.yml'

      def call(config: nil, verbose: false, **)
        setup(config: config, verbose: verbose)
        config_file = config || File.join(ENV['HOME'], '.astro-subframe-organizer.yml')

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
        }
        require 'yaml'
        File.write(config_file, default_config.to_yaml)
        puts 'Created default config file at ~/.astro-subframe-organizer.yml'
        puts 'Edit this file to customize your telescopes, filters, and cameras.'
      end
    end
  end
end
