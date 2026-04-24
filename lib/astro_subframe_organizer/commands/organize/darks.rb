# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Darks < Dry::CLI::Command
        include SharedOptions

        desc 'Run the subframe organizer for dark calibration frames'

        def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
          setup(config: config, verbose: verbose)
          Organizer.new(type: Astrophoto::DARK, path: path).organize(dry_run: dry_run)
        end
      end
    end
  end
end
