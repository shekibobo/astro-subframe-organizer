# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Run < Dry::CLI::Command
      include SharedOptions

      desc 'Run the subframe organizer interactively'

      example [
        '                             # Basic usage, using default values or values from default config file at ~/.astro-subframe-organizer.yml',
        '--config ~/.custom-setup.yml # Uses alternative setup with specific equipment',
        '--verbose                    # Log more details while running',
        '--skip-confirm               # Skip confirmation step before moving files',
      ]

      def call(**options)
        setup(**options.slice(:config, :verbose, :skip_confirm))
        AstroSubframeOrganizer.run
      end
    end
  end
end
