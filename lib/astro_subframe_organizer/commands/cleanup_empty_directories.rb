# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    class CleanupEmptyDirectories < Dry::CLI::Command
      include SharedOptions

      desc 'Remove empty directories'

      def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
        setup(config: config, verbose: verbose)
        AstroSubframeOrganizer::Utils::EmptyDirectoryCleaner.new(path).cleanup(dry_run: dry_run, verbose: verbose)
      end
    end
  end
end
