# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Run < Dry::CLI::Command
      include SharedOptions

      desc 'Run the subframe organizer interactively'

      # rubocop:disable Layout/LineLength
      example [
        '                             # Basic usage, using default values or values from default config file at ~/astro-subframe-organizer-config.yml',
        '--config ~/.custom-setup.yml # Uses alternative setup with specific equipment',
        '--verbose                    # Log more details while running',
        '--skip-confirm               # Skip confirmation step before moving files',
        '--dry-run                    # Run interactively, dry-run only',
      ]
      # rubocop:enable Layout/LineLength

      def call(**options)
        setup(**options.slice(:config, :verbose, :skip_confirm))
        AstroSubframeOrganizer.run(dry_run: options[:dry_run])
      end
    end
  end
end
