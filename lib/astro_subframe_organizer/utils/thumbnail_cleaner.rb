# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    # A cleanup utility that removes thumbnail images with filenames mattching `pattern`
    # from `path` and all its subdirectories.
    class ThumbnailCleaner
      include Logging

      ASIAIR_THUMBNAIL_PATTERN = '**/**_thn.jpg'

      attr_reader :path

      def initialize(path = Dir.pwd)
        @path = path
      end

      # Removes all the jpg thumbnails under the given directory.
      def cleanup(pattern: ASIAIR_THUMBNAIL_PATTERN, dry_run: false, verbose: false)
        logger.info 'Removing jpg thumbnails...'
        Dir.glob([pattern], base: path)
           .each { |thumbnail| FileUtils.rm File.join(path, thumbnail), noop: dry_run, verbose: verbose }
      end
    end
  end
end
