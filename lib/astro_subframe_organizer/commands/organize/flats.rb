# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Flats < Dry::CLI::Command
        include SharedOptions

        desc 'Run the subframe organizer for flat calibration frames'

        def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
          setup(config: config, verbose: verbose)
          Organizer.new(type: Astrophoto::FLAT, path: path).organize(dry_run: dry_run)
        end
      end
    end
  end
end
