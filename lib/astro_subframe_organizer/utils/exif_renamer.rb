# frozen_string_literal: true

require 'mini_exiftool'

module AstroSubframeOrganizer
  module Utils
    # Renames CR2 files based on EXIF data to match the standard subframe naming
    # convention: TYPE_TARGET_EXPTIME_BIN_CAMERA_ISO_DATETIME_TEMP_SEQ.CR2
    class ExifRenamer
      include Logging

      DT_FORMAT = '%Y%m%dT%H%M%S'

      attr_reader :path

      def initialize(path = Dir.pwd)
        @path = path
      end

      def rename(type:, target: nil, dry_run: false)
        logger.info 'Renaming files from EXIF data...'
        cr2_files = find_cr2_files

        if cr2_files.empty?
          logger.warn 'No CR2 files found.'
          return
        end

        cr2_files.each do |cr2|
          rename_file(cr2, type: type, target: target, dry_run: dry_run)
        end

        logger.info 'Done'
      end

      def already_named?(files)
        files.none? { |cr2| File.basename(cr2).start_with?('IMG_') }
      end

      def find_cr2_files
        Dir.glob(['*.cr2', '*.CR2'], base: path)
           .map { |f| File.join(path, f) }
           .uniq
      end

      private

      def rename_file(cr2, type:, target:, dry_run:)
        exif = load_exif(cr2)
        target_file = File.join(path, build_filename(exif, type: type, target: target))

        if File.exist?(target_file)
          logger.warn "Skipping #{cr2}, target #{target_file} already exists."
          return
        end

        FileUtils.mv(cr2, target_file, verbose: dry_run, noop: dry_run)
        print '.' unless dry_run
      end

      def load_exif(cr2)
        exif = MiniExiftool.new(cr2)
        exif['SequenceNumber'] = derive_sequence_number(exif) if exif['SequenceNumber'].to_i == 0
        exif['Artist'] = 'Joshua Kovach'
        exif.save
        exif.reload
        exif
      end

      def derive_sequence_number(exif)
        exif.filename.split('_').last.split('.').first.to_i
      end

      def build_filename(exif, type:, target:)
        data       = exif.to_hash
        exp_str    = format_exposure(data['ExposureTime'])
        created_at = data['DateTimeOriginal'].strftime(DT_FORMAT)
        ccd_temp   = format('%.1fC', data['CameraTemperature'].to_f)
        seq_num    = data['SequenceNumber'].to_s.rjust(4, '0')
        camera     = resolve_camera(data['Model'])

        [type, target, exp_str, 'Bin1', camera, "ISO#{data['ISO']}", created_at, ccd_temp, seq_num]
          .compact
          .join('_') + '.CR2'
      end

      def format_exposure(exp_time)
        exp_time  = exp_time.to_f
        unit      = 's'
        if exp_time < 1.0
          exp_time *= 1000
          unit = 'ms'
        end
        if exp_time < 1.0
          exp_time *= 1000
          unit = 'us'
        end
        format('%.1f%s', exp_time, unit)
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
    end
  end
end
