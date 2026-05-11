# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    # A cleanup utility that removes empty directories from `path` and all
    # its subdirectories. Useful after organizing and moving subframes.
    class EmptyDirectoryCleaner
      include Logging

      attr_reader :path

      def initialize(path = Dir.pwd)
        @path = path
      end

      # Removes empty directories under the given directory.
      def cleanup(dry_run: false, verbose: false)
        logger.info 'Cleaning up empty directories...'

        Dir.glob('**//*/', base: path).reverse_each do |dir|
          full_path = File.join(path, dir)
          entries   = Dir.entries(full_path) - ['.', '..', '.DS_Store']

          next unless entries.empty?

          unless dry_run
            ds_store = File.join(full_path, '.DS_Store')
            FileUtils.rm(ds_store, verbose: verbose) if File.exist?(ds_store)
            FileUtils.rmdir(full_path, verbose: verbose)
          end
          logger.debug "rmdir #{full_path}"
        end
      end
    end
  end
end
