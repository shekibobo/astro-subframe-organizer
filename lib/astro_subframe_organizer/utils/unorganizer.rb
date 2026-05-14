# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    # Moves all FITS and CR2 files from subdirectories back into the target directory.
    # Useful for undoing an organize run so files can be re-organized with different settings.
    class Unorganizer
      include Logging

      attr_reader :path

      def initialize(path = Dir.pwd)
        @path = path
      end

      def unorganize(dry_run: false, verbose: false)
        files = find_organized_files

        if files.empty?
          logger.info 'No organized files found.'
          return
        end

        logger.info "Preparing to move #{files.size} files to #{path}..."

        bar = TTY::ProgressBar.new('Moving files [:bar] :current/:total (:percent) :eta', total: files.size)

        files.each do |file|
          dest = File.join(path, File.basename(file))
          if File.exist?(dest)
            bar.log "Skipping #{File.basename(file)}, already exists in #{path}."
            next
          end
          FileUtils.mv(file, dest, verbose: verbose || dry_run, noop: dry_run)
          bar.advance(1)
        end

        cleanup_empty_dirs(dry_run: dry_run) unless dry_run
      end

      private

      def find_organized_files
        Dir.glob(['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'], base: path)
           .map { |f| File.join(path, f) }
           .reject { |f| File.dirname(f) == path }
      end

      def cleanup_empty_dirs(dry_run: false, verbose: false)
        EmptyDirectoryCleaner.new(path).cleanup(dry_run: dry_run, verbose: verbose)
      end
    end
  end
end
