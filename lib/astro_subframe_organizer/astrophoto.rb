# frozen_string_literal: true

require 'forwardable'

module AstroSubframeOrganizer
  # Class describing the properties of the file that we can determine from the filename generated
  # by the ASIAir. Depending on your camera and your filter setup, the file structure may be different.
  # This script was written for use with the ASIAir Plus version 1.9, using a Canon EOS 1500 (T7) DSLR
  # camera with all the filename metadata turned on. You may have more metadata, or a different order of
  # metadata depending on which camera setup you have, or if you have an EFW (electronic filter wheel).
  # In that case, you will need to change the order or add more properties in the initialize method so
  # that your data is properly parsed. You will also likely want to change your `target_dir` for each
  # type so that it organizes your data properly.
  class Astrophoto
    include Logging
    extend Forwardable

    def_delegators :file_metadata,
                   :bin,
                   :camera,
                   :ccd_temp,
                   :created_at,
                   :dark_flat,
                   :dark_flat?,
                   :dark_flat=,
                   :exposure,
                   :file_format,
                   :filename,
                   :filter,
                   :flatset_id,
                   :gain,
                   :image_index,
                   :iso,
                   :maybe_flat_dark?,
                   :month,
                   :mosaic_pane,
                   :path,
                   :path=,
                   :rounded_ccd_temp,
                   :target,
                   :target=,
                   :telescope,
                   :type,
                   :type=

    TYPES = [
      DARK = 'Dark',
      FLAT = 'Flat',
      LIGHT = 'Light',
      BIAS = 'Bias',
    ]

    def initialize(path)
      @file_parser = FilenameParser.for_file(path)
    end

    def file_metadata
      @file_metadata ||= @file_parser.parse
    end

    def telescope=(value)
      @target_dir = nil
      @target_path = nil
      file_metadata.telescope = value
    end

    def camera=(value)
      @target_dir = nil
      @target_path = nil
      file_metadata.camera = value
    end

    def filter=(value)
      @target_dir = nil
      @target_path = nil
      file_metadata.filter = value
    end

    # The directory structure used to group and categorize the files, which will include useful
    # grouping keywords for PixInsight's WeightedBatchPreProcessing script.
    def target_dir
      @target_dir ||= File.join(current_dir, PathBuilder.build_for(file_metadata))
    end

    # The full path where this file will be moved.
    def target_path
      @target_path ||= File.join(target_dir, filename)
    end

    # The current directory of the file. If this is different from the target directory,
    # you will be asked whether you want to move it or not.
    def current_dir
      File.dirname(path)
    end

    # True if the path is already at the target destination. We don't need to move or ask
    # anything about these files.
    def already_moved?
      file_metadata.already_moved?(target_path)
    end

    # Performs the move. If `is_dry_run` is true, it will not move the files, but will output
    # the file's current location and target location so you can verify it is correct before
    # performing the actual move.
    def move(is_dry_run, bar = nil)
      destination = target_path
      dest_dir    = target_dir

      # Logic to create directory
      FileUtils.mkdir_p(dest_dir) unless is_dry_run || File.exist?(dest_dir)

      if File.exist?(destination)
        # NOTE: Frequent logging can cause the progress bar to flicker or move
        msg = "File already exists #{destination}. Skipping..."
        bar ? bar.log(msg) : logger.warn(msg)
      else
        FileUtils.move(path, destination, verbose: is_dry_run, noop: is_dry_run)
        self.path = destination unless is_dry_run
      end
    end
  end
end
