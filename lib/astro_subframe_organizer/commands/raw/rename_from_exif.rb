# frozen_string_literal: true

require 'astro_subframe_organizer/astrophoto'

module AstroSubframeOrganizer
  module Commands
    module Raw
      class RenameFromExif < Dry::CLI::Command
        include SharedOptions

        desc 'Rename CR2 files using EXIF metadata. Use on generically named RAW (CR2) files prior to organization.'

        option :type,
               type: :string,
               required: true,
               values: AstroSubframeOrganizer::Astrophoto::TYPES,
               desc: "Frame type (#{Astrophoto::TYPES.join(', ')})"

        option :target,
               type: :string,
               required: false,
               desc: 'Target name (required for light frames)'

        def call(type:, dry_run: false, path: Dir.pwd, target: nil, **options)
          setup(**options.slice(:config, :verbose, :skip_confirm))

          if type == Astrophoto::LIGHT && target.nil?
            logger.error 'A --target is required for light frames.'
            exit 1
          end

          renamer = AstroSubframeOrganizer::Utils::ExifRenamer.new(path)

          if renamer.already_named?(renamer.find_cr2_files)
            logger.warn 'Files appear to already be renamed. Use --force to rename anyway.'
            exit 0
          end

          renamer.rename(type: type, target: target, dry_run: dry_run)
        end
      end
    end
  end
end
