# frozen_string_literal: true

require 'dry/cli'
require 'astro_subframe_organizer/utils/thumbnail_cleaner'

module AstroSubframeOrganizer
  module Commands
    module Cleanup
      class Thumbnails < Dry::CLI::Command
        include SharedOptions

        THUMBNAIL_PATTERN = AstroSubframeOrganizer::Utils::ThumbnailCleaner::ASIAIR_THUMBNAIL_PATTERN

        desc "Delete all thumbnail images. Default matches #{THUMBNAIL_PATTERN}."

        example [
          "                           # Default, matches #{THUMBNAIL_PATTERN}",
          "--pattern '**/*_thumb.png' # Use a custom pattern to match thumbnails",
        ]

        option :pattern,
               type: :string,
               default: THUMBNAIL_PATTERN,
               required: false,
               desc: 'A glob pattern to match thumbnail files.'

        def call(dry_run: false, path: Dir.pwd, pattern: THUMBNAIL_PATTERN, **options)
          setup(**options.slice(:config, :verbose, :skip_confirm))
          AstroSubframeOrganizer::Utils::ThumbnailCleaner.new(path).cleanup(pattern: pattern, dry_run: dry_run, verbose: options[:verbose])
        end
      end
    end
  end
end
