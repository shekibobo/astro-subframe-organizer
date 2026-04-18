# frozen_string_literal: true

require_relative 'camera'

# Class describing the properties of the file that we can determine from the filename generated
# by the ASIAir. Depending on your camera and your filter setup, the file structure may be different.
# This script was written for use with the ASIAir Plus version 1.9, using a Canon EOS 1500 (T7) DSLR
# camera with all the filename metadata turned on. You may have more metadata, or a different order of
# metadata depending on which camera setup you have, or if you have an EFW (electronic filter wheel).
# In that case, you will need to change the order or add more properties in the initialize method so
# that your data is properly parsed. You will also likely want to change your `target_dir` for each
# type so that it organizes your data properly.
class Astrophoto
  DT_FORMAT = '%Y%m%d-%H%M%S'

  attr_accessor :type, :exposure, :bin, :camera, :gain, :iso, :created_at, :ccd_temp, :image_index, :path, :filename, :telescope,
                :filter, :target, :dark_flat, :mosaic_pane

  TYPES = [
    DARK = 'Dark',
    FLAT = 'Flat',
    LIGHT = 'Light',
    BIAS = 'Bias'
  ]

  def initialize(path)
    self.path = path
    self.filename = path.split('/').last
    parts = filename.gsub('.fit', '').gsub('.cr2', '').split('_')
    puts "PARTS: #{parts}"
    self.type = parts.shift
    puts "TYPE: #{type}"

    self.target = parts.shift if type == LIGHT
    puts "TARGET: #{target}"
    self.mosaic_pane = parts.shift if parts.first.match(/\A\d+-\d+\z/)
    puts "PANE: #{mosaic_pane}"

    # If the file is already organized somewhere, get the information from its path.
    self.telescope = path.match(%r{TELESCOPE_([^_/]+).*})&.captures&.first
    puts "TELESCOPE: #{telescope}"
    self.filter = path.match(%r{FILTER_([^_/]+).*})&.captures&.first
    puts "FILTER: #{filter}"
    self.dark_flat = path.include?('DarkFlat')
    puts "DarkFlat?: #{dark_flat}"

    self.exposure = parts.shift
    puts "EXP: #{exposure}"

    self.bin = parts.shift.gsub('Bin', '') if parts.first.start_with?('Bin')
    puts "BIN: #{bin}"

    self.camera = parts.shift if Camera::ALL.include?(parts.first)
    puts "CAMERA: #{camera}"

    self.iso = parts.shift.gsub('ISO', '') if parts.first.start_with?('ISO')
    puts "ISO: #{iso}"
    self.gain = parts.shift.gsub('gain', '') if parts.first.start_with?('gain')
    puts "GAIN: #{gain}"

    self.created_at = DateTime.strptime(parts.shift, DT_FORMAT)
    puts "CREATED_AT: #{created_at}"
    self.ccd_temp = parts.shift
    puts "CCD_TEMP: #{ccd_temp}"
    self.image_index = parts.shift
    puts "IMAGE_INDEX: #{image_index}"
  end

  def dark_flat?
    dark_flat
  end

  # True if the dark is likely a dark flat and hasn't already been organized as dark flat.
  def maybe_flat_dark?
    exp_val = exposure.to_f
    exp_units = exposure.gsub(exp_val.to_s, '')
    exp_in_seconds = case exp_units
                     when 's'
                       exp_val
                     when 'ms'
                       exp_val / 1000.0
                     when 'us'
                       exp_val / 1_000_000.0
                     end
    type == DARK && exp_in_seconds <= 10.0 && !dark_flat?
  end

  # The date formatted like '20220508'. If the pictures are taken in the latter half of the
  # day, we are assuming that we'll use the flatset that will be generated the next day.
  def flatset_id
    if type == LIGHT && created_at.hour >= 12
      created_at.next_day.strftime('%Y%m%d')
    else
      created_at.strftime('%Y%m%d')
    end
  end

  # The Year-Month in which the image was taken. Useful for grouping darks by season.
  def month
    created_at.strftime('%Y-%m')
  end

  # The file format (:fits or :cr2) based on the filename extension.
  def file_format
    if filename.downcase.end_with?('.fit')
      :fits
    elsif filename.downcase.end_with?('.cr2')
      :cr2
    else
      raise ArgumentError, "Unsupported file format for: #{filename}"
    end
  end

  # The directory structure used to group and categorize the files, which will include useful
  # grouping keywords for PixInsight's WeightedBatchPreProcessing script.
  def target_dir
    AstroSubframeOrganizer::PathBuilder.build_for(self)
  end

  # The full path where this file will be moved.
  def target_path
    File.join(target_dir, filename)
  end

  # The current directory of the file. If this is different from the target directory,
  # you will be asked whether you want to move it or not.
  def current_dir
    segments = File.split(path) - [filename]
    File.join(*segments)
  end

  # True if the path is already at the target destination. We don't need to move or ask
  # anything about these files.
  def already_moved?
    path == target_path
  end

  # Performs the move. If `is_dry_run` is true, it will not move the files, but will output
  # the file's current location and target location so you can verify it is correct before
  # performing the actual move.
  def move(is_dry_run)
    FileUtils.mkdir target_dir, noop: is_dry_run unless File.exist? target_dir
    if File.exist? target_path
      puts "File already exists #{target_path}. Skipping..."
    else
      FileUtils.move path, target_path, verbose: is_dry_run, noop: is_dry_run
      print '.' unless is_dry_run
    end
  end
end
