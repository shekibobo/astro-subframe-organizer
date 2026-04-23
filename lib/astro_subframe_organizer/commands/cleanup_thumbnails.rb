# frozen_string_literal: true

require 'dry/cli'
require 'astro_subframe_organizer/utils/thumbnail_cleaner'

module AstroSubframeOrganizer
  module Commands
    class CleanupThumbnails < Dry::CLI::Command
      include SharedOptions

      THUMBNAIL_PATTERN = AstroSubframeOrganizer::Utils::ThumbnailCleaner::ASIAIR_THUMBNAIL_PATTERN

      option :pattern,
             type: :string,
             default: THUMBNAIL_PATTERN,
             required: false,
             desc: 'A glob pattern to match thumbnail files.'

      def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, pattern: THUMBNAIL_PATTERN, **)
        setup(config: config, verbose: verbose)
        AstroSubframeOrganizer::Utils::ThumbnailCleaner.new(path).cleanup(pattern: pattern, dry_run: dry_run, verbose: verbose)
      end
    end
  end
end
