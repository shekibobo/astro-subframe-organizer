# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Cleanup
      class Unorganize < Dry::CLI::Command
        include SharedOptions

        desc 'Move all FITS and CR2 files from subdirectories back into the target directory'

        example [
          '# Default, move all .fit and .cr2 files to the current directory and delete empty subdirectories',
          '--path ~/astrophotography/organized # Move all organized .fit and .cr2 files into ~/astrophotography/organized and delete the empty subdirectories',
        ]

        def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
          setup(config: config, verbose: verbose)
          AstroSubframeOrganizer::Utils::Unorganizer.new(path).unorganize(dry_run: dry_run, verbose: verbose)
        end
      end
    end
  end
end
