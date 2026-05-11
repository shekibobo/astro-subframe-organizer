# frozen_string_literal: true

require 'astro_subframe_organizer/utils/exif_renamer'

module AstroSubframeOrganizer
  module Commands
    module Raw
      class RevertToRaw < Dry::CLI::Command
        include SharedOptions

        desc 'Revert previously renamed CR2 files to their original names (IMG_XXXX.CR2)'

        def call(dry_run: false, path: Dir.pwd, **options)
          setup(**options.slice(:config, :verbose, :skip_confirm))

          renamer = AstroSubframeOrganizer::Utils::ExifRenamer.new(path)

          unless renamer.already_named?(renamer.find_cr2_files)
            logger.warn 'Files appear to already be renamed. Use --force to rename anyway.'
            exit 0
          end

          renamer.revert(dry_run: dry_run)
        end
      end
    end
  end
end
