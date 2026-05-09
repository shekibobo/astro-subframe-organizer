# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Cleanup
      class Unorganize < Dry::CLI::Command
        include SharedOptions

        desc 'Move all FITS and CR2 files from subdirectories back into the target directory'

        def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
          setup(config: config, verbose: verbose)
          AstroSubframeOrganizer::Utils::Unorganizer.new(path).unorganize(dry_run: dry_run, verbose: verbose)
        end
      end
    end
  end
end
