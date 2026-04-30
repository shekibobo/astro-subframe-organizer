# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Cleanup
      class EmptyDirectories < Dry::CLI::Command
        include SharedOptions

        desc 'Remove empty directories'

        def call(dry_run: false, path: Dir.pwd, **options)
          setup(**options.slice(:config, :verbose, :skip_confirm))
          AstroSubframeOrganizer::Utils::EmptyDirectoryCleaner.new(path).cleanup(dry_run: dry_run, verbose: options[:verbose])
        end
      end
    end
  end
end
