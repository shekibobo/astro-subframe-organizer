# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Run < Dry::CLI::Command
      desc 'Run the subframe organizer'

      option :config, desc: 'Use custom config file (default: ~/.astro-subframe-organizer.yml)'

      def call(config: nil, **)
        ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG'] = config if config
        AstroSubframeOrganizer.run
      end
    end
  end
end
