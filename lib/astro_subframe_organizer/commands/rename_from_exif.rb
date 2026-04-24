# frozen_string_literal: true

require 'astro_subframe_organizer/astrophoto'

module AstroSubframeOrganizer
  module Commands
    class RenameFromExif < Dry::CLI::Command
      include SharedOptions

      desc 'Rename CR2 files using EXIF metadata'

      option :type,
             type: :string,
             required: true,
             values: AstroSubframeOrganizer::Astrophoto::TYPES,
             desc: "Frame type (#{Astrophoto::TYPES.join(', ')})"

      option :target,
             type: :string,
             required: false,
             desc: 'Target name (required for light frames)'

      def call(type:, config: nil, verbose: false, dry_run: false, path: Dir.pwd, target: nil, **)
        setup(config: config, verbose: verbose)

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
