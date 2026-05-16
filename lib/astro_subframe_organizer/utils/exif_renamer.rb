# frozen_string_literal: true

require 'exiftool_vendored'

module AstroSubframeOrganizer
  module Utils
    # Renames CR2 files based on EXIF data to match the standard subframe naming
    # convention: TYPE_TARGET_EXPTIME_BIN_CAMERA_ISO_DATETIME_TEMP_SEQ.CR2
    class ExifRenamer
      include Logging
      include ExposureFormat

      EXIF_DT_FORMAT = '%Y:%m:%d %H:%M:%S%z'

      attr_reader :path

      def initialize(path = Dir.pwd)
        @path = path
      end

      def rename(type:, target: nil, dry_run: false)
        Exiftool.command = 'exiftool.exe' if Gem.win_platform?

        cr2_files = find_cr2_files

        if cr2_files.empty?
          logger.warn 'No CR2 files found.'
          return
        end

        e = Exiftool.new(cr2_files)
        bar = TTY::ProgressBar.new('Renameing files from EXIF data [:bar] :current/:total (:percent) :eta', total: e.files_with_results.size)

        e.files_with_results.each do |cr2|
          exif = e.result_for(cr2)
          rename_file(cr2, exif, type: type, target: target, dry_run: dry_run, bar: bar)
        end
      end

      def already_named?(files)
        files.none? { |cr2| File.basename(cr2).start_with?('IMG_') }
      end

      def find_cr2_files
        Dir.glob(['**/*.cr2', '**/*.CR2'], base: path)
           .map { |f| File.join(path, f) }
           .uniq
      end

      def revert(dry_run: false)
        cr2_files = find_cr2_files # recursive search

        if cr2_files.empty?
          logger.warn 'No CR2 files found.'
          return
        end

        cr2_files.each_with_index do |file, index|
          idx         = derive_sequence_number_from_filename(file) || (index + 1)
          filename    = "IMG_#{idx.to_s.rjust(4, '0')}.CR2"
          target_file = File.join(File.dirname(file), filename)

          logger.info "Renaming #{File.basename(file)} to #{filename}"
          FileUtils.move(file, target_file, verbose: dry_run, noop: dry_run) unless File.exist?(target_file)
        end
      end

      private

      def rename_file(cr2, exif, type:, target:, dry_run:, bar: nil)
        target_file = File.join(File.dirname(cr2), build_filename(exif, type: type, target: target))

        if File.exist?(target_file)
          msg = "Skipping #{cr2}, target #{target_file} already exists."
          bar ? bar.log(msg) : logger.warn(msg)
          return
        end

        FileUtils.mv(cr2, target_file, verbose: dry_run, noop: dry_run)
      end

      def derive_sequence_number_from_filename(path)
        File.basename(path, '.*').split(/[_-]/).last.to_i
      end

      def build_filename(exif, type:, target:)
        exp_str    = format_exposure(exif[:exposure_time])
        created_at = resolve_time(exif).strftime(FILENAME_DT_FORMAT)
        ccd_temp   = format('%.1fC', exif[:camera_temperature].to_f)
        seq_num    = derive_sequence_number_from_filename(exif.source_file).to_s.rjust(4, '0')
        camera     = resolve_camera(exif[:model])

        [type, target, exp_str, 'Bin1', camera, "ISO#{exif[:iso]}", created_at, ccd_temp, seq_num]
          .compact
          .join('_') + '.CR2'
      end

      def resolve_camera(cam_model)
        camera = Equipment::Camera.all.find { |it| cam_model.include?(it) }
        if camera.nil?
          logger.warn "Camera #{cam_model} did not match any expected models."
          cam_model
        else
          camera
        end
      end

      def resolve_time(exif)
        Time.strptime(exif[:date_time_original] + exif[:time_zone], EXIF_DT_FORMAT)
      end
    end
  end
end
