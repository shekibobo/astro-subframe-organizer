# Copyright 2022 Joshua Kovach
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

require 'fileutils'
require 'date_core'
require 'highline'
require 'mini_exiftool'

# Add your telescopes here. You will be prompted to choose one of them when organizing flats and lights.
class Telescope
  ALL = [
    REDCAT51 = 'RedCat51',
    Z130 = 'ZhumellZ130',
    AD8 = 'AperturaAD8',
    DS90 = 'MeadeDS90',
  ]
end

# Add your filters here. You will be prompted to choose one of them when organizing flats and lights.
class Filter
  ALL = [
    BAADER_MOON = 'BaaderMoon',
    NBZ = "NBZ",
    NONE = 'NoFilter',
  ]
end

# Add your cameras here. If there is no camera chosen, it will prompt you to choose one.
class Camera
  ALL = [
    CANON_T7 = "T7",
    ASI183MC = "183MC",
  ]
end

DT_FORMAT = '%Y%m%d-%H%M%S'

# Class describing the properties of the file that we can determine from the filename generated
# by the ASIAir. Depending on your camera and your filter setup, the file structure may be different.
# This script was written for use with the ASIAir Plus version 1.9, using a Canon EOS 1500 (T7) DSLR
# camera with all the filename metadata turned on. You may have more metadata, or a different order of
# metadata depending on which camera setup you have, or if you have an EFW (electronic filter wheel).
# In that case, you will need to change the order or add more properties in the initialize method so
# that your data is properly parsed. You will also likely want to change your `target_dir` for each
# type so that it organizes your data properly.
class Astrophoto
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

  # The directory structure used to group and categorize the files, which will include useful
  # grouping keywords for PixInsight's WeightedBatchPreProcessing script.
  def target_dir
    iso_or_gain = if iso != nil
                    "ISO_#{iso}"
                  elsif gain != nil
                    "GAIN_#{gain}"
                  end

    case type
    when DARK
      if dark_flat?
        "DarkFlat_FLATSET_#{flatset_id}_#{iso_or_gain}_EXP_#{exposure}_Bin_#{bin}_CAMERA_#{camera}"
      else
        "Dark_#{iso_or_gain}_EXP_#{exposure}_CCD-TEMP_#{ccd_temp}_CAMERA_#{camera}_MONTH_#{month}"
      end
    when FLAT
      "Flat_FLATSET_#{flatset_id}_#{iso_or_gain}_EXP_#{exposure}_Bin_#{bin}_TELESCOPE_#{telescope}_FILTER_#{filter}_CAMERA_#{camera}"
    when LIGHT
      pane_id = "_PANE_#{mosaic_pane}" if mosaic_pane
      if filename.downcase.end_with?(".fit")
        "Light_#{target}#{pane_id}_FLATSET_#{flatset_id}_#{iso_or_gain}_EXP_#{exposure}_Bin_#{bin}_TELESCOPE_#{telescope}_FILTER_#{filter}_CAMERA_#{camera}"
      elsif filename.downcase.end_with?(".cr2")
        "Light_#{target}#{pane_id}_FLATSET_#{flatset_id}_#{iso_or_gain}_EXP_#{exposure}_Bin_#{bin}_CCD-TEMP_#{ccd_temp.gsub("0C", "")}_TELESCOPE_#{telescope}_FILTER_#{filter}_CAMERA_#{camera}"
      end
    when BIAS
      "Bias_#{iso_or_gain}_EXP_#{exposure}_Bin_#{bin}_CAMERA_#{camera}_MONTH_#{month}"
    end
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
      print "." unless is_dry_run
    end
  end
end

class FitsOrganizer
  private attr_accessor :cli

  def initialize
    self.cli = HighLine.new
  end

  def fits_files
    Dir['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'].uniq.map { |it| Astrophoto.new(it) }
  end

  # Organizes dark files by ISO, BIN, CCD-TEMP, EXPOSURE, and MONTH to facilitate the creation of
  # master darks that may have varying temperatures. This organization can be changed by updating
  # Astrophoto#target_dir for the DARK type.
  #
  # If the file has an exposure of less than 10 seconds, you will be asked if it is a flat dark.
  # If so, it will be organized into a folder that will match your corresponding flat files so that
  # you can run WBPP with just your biases, flat darks, and flats using the grouping keywords
  # FLATSET, BIN, EXP, and ISO. CCD-TEMP will be ignored for the purposes of these files, as it is
  # assumed they will be taken under roughly the same conditions as the flats are taken.
  #
  # If the files are normal dark files, they will be organized by ISO, EXPOSURE, BIN, CCD-TEMP, and MONTH.
  # With this, you can run WBPP with just bias and darks using the grouping keywords CCD-TEMP, ISO, EXP,
  # and MONTH (optional).
  def organize_darks
    dark_files = fits_files.filter { |it| it.type == Astrophoto::DARK }.sort_by { |it| it.path }
    puts "Preparing to move #{dark_files.size} DARK files..."

    is_dry_run = is_dry_run?

    dark_files.slice_when { |a, b| a.image_index.to_i > b.image_index.to_i }.each do |darkset|
      next if darkset.all? { |it| it.already_moved? }

      if darkset.all? { |it| it.path != it.target_path }
        move = cli.ask("Do you want to move the darkset in #{darkset.first.current_dir} to #{darkset.first.target_dir}? [y/n] ").downcase == 'y'
        next unless move
      end

      if darkset.all? { |it| it.maybe_flat_dark? } &&
        cli.ask("Is this a flat dark set (size #{darkset.size})? [y/n] #{darkset.first.filename}: ").downcase == 'y'
        puts "Cool, we'll move that set to a FLATSET directory..."

        darkset.each { |it| it.dark_flat = true }
      end

      cameras = darkset.map { |it| it.camera }.uniq
      camera = if cameras.empty?
                 puts "[WARNING] Camera not detected."
                 select_camera
               elsif cameras.size > 1
                 puts "[WARNING] Multiple cameras detected: #{cameras}"
               else
                 cameras.first
               end

      darkset.each do |file|
        if file.camera.nil?
          puts "Camera not detected. Using #{camera}."
          file.camera = camera
        end
      end

      darkset.each { |it| it.move(is_dry_run) }
    end
    puts "Done"
  end

  def organize_biases
    bias_files = fits_files.filter { |it| it.type == Astrophoto::BIAS }.sort_by { |it| it.path }
    puts "Preparing to move #{bias_files.size} BIAS files..."

    is_dry_run = is_dry_run?

    bias_files.slice_when { |a, b| a.image_index.to_i > b.image_index.to_i }.each do |biases|
      next if biases.all? { |it| it.already_moved? }

      if biases.all? { |it| it.path != it.target_path }
        move = cli.ask("Do you want to move the bias set in #{biases.first.current_dir} to #{biases.first.target_dir}? [y/n] ").downcase == 'y'
        next unless move
      end

      cameras = biases.map { |it| it.camera }.uniq
      camera = if cameras.empty?
                 puts "[WARNING] Camera not detected."
                 select_camera
               elsif cameras.size > 1
                 puts "[WARNING] Multiple cameras detected: #{cameras}"
               else
                 cameras.first
               end

      biases.each do |file|
        if file.camera.nil?
          puts "Camera not detected. Using #{camera}."
          file.camera = camera
        end
      end

      biases.each { |it| it.move(is_dry_run) }
    end
    puts "Done"
  end

  # Organizes flat files by FLATSET, ISO, BIN, EXP (EXPOSURE), TELESCOPE, and FILTER. To change these
  # properties, update Astrophoto#target_dir for the FLAT type. The TELESCOPE and FILTER keywords are
  # for matching LIGHTS which will have the same keywords set when organized using this script.
  #
  # You can run WBPP with just your biases, flat darks, and flats using the grouping keywords
  # FLATSET, BIN, EXP, and ISO. CCD-TEMP will be ignored for the purposes of these files, as it is
  # assumed they will be taken under roughly the same conditions as the flat darks are taken.
  #
  # After running WBPP, you should delete the `EXP` keyword from the master flat file name (if present)
  # before using that master flat in a WBPP integration run, since exposure time should not be considered
  # when grouping flats to lights.
  def organize_flats
    flat_files = fits_files.filter { |it| it.type == Astrophoto::FLAT }.sort_by { |it| it.path }
    puts "Preparing to move #{flat_files.size} FLAT files..."

    is_dry_run = is_dry_run?

    flat_sets = flat_files.slice_when { |a, b| a.image_index.to_i > b.image_index.to_i }

    flat_sets.each do |flatset|
      next if flatset.all? { |it| it.already_moved? }

      if flatset.all? { |it| it.path != it.target_path }
        move = cli.ask("Do you want to move the flatset in #{flatset.first.current_dir} to #{flatset.first.target_dir}? [y/n] ").downcase == 'y'
        next unless move
      end

      puts "For FLATSET #{flatset.first.filename}..#{flatset.last.filename}:"
      telescope = select_telescope
      filter = select_filter
      cameras = flatset.map { |it| it.camera }.uniq
      camera = if cameras.empty?
                 puts "[WARNING] Camera not detected."
                 select_camera
               elsif cameras.size > 1
                 puts "[WARNING] Multiple cameras detected: #{cameras}"
               else
                 cameras.first
               end

      flatset.each do |file|
        file.telescope = telescope
        file.filter = filter
        if file.camera.nil?
          puts "Camera not detected. Using #{camera}."
          file.camera = camera
        end
      end

      flatset.each { |it| it.move(is_dry_run) }
    end
    puts "Done"
  end

  # Organizes light files by FLATSET, ISO, BIN, EXP (EXPOSURE), TELESCOPE, and FILTER. To change these
  # properties, update Astrophoto#target_dir for the LIGHT type. The TELESCOPE and FILTER keywords are
  # for matching LIGHTS which will have the same keywords set when organized using this script.
  #
  # CCD-TEMP is ignored in the group naming because each individual fits file contains that information
  # in its fits header.
  #
  # You can run WBPP with just your master biases, master darks, and master flats using the grouping
  # keywords FLATSET, BIN, EXP, CCD-TEMP, and ISO.
  #
  # If you are running WBPP on multiple targets using this data, e.g. for a mosaic, you should make sure
  # to use LIGHT as a post-processing keyword and register files using `auto by LIGHT`.
  def organize_lights
    light_files = fits_files.filter { |it| it.type == Astrophoto::LIGHT }.sort_by { |it| it.path }
    puts "Preparing to move #{light_files.size} LIGHT files..."

    is_dry_run = is_dry_run?

    light_sets = light_files.slice_when { |a, b| a.image_index.to_i > b.image_index.to_i }

    light_sets.each do |lightset|
      next if lightset.all? { |it| it.already_moved? }

      if lightset.all? { |it| it.path != it.target_path }
        move = cli.ask("Do you want to move the light set in #{lightset.first.current_dir} to #{lightset.first.target_dir}? [y/n] ").downcase == 'y'
        next unless move
      end

      puts "For LIGHTS #{lightset.first.filename}..#{lightset.last.filename}:"
      telescope = select_telescope
      filter = select_filter
      cameras = lightset.map { |it| it.camera }.uniq
      camera = if cameras.empty?
                 puts "[WARNING] Camera not detected."
                 select_camera
               elsif cameras.size > 1
                 puts "[WARNING] Multiple cameras detected: #{cameras}"
               else
                 cameras.first
               end

      lightset.each do |file|
        file.telescope = telescope
        file.filter = filter
        if file.camera.nil?
          puts "Camera not detected. Using #{camera}."
          file.camera = camera
        end
      end

      lightset.each { |it| it.move(is_dry_run) }
    end
    puts "Done"
  end

  private def select_telescope
    cli.choose do |menu|
      menu.prompt = 'What telescope is this set for?'
      Telescope::ALL.each do |scope|
        menu.choice(scope)
      end
      menu.default = Telescope::REDCAT51
    end
  end

  private def select_filter
    cli.choose do |menu|
      menu.prompt = 'What filter is used with this set?'
      Filter::ALL.each do |filter|
        menu.choice(filter)
      end
      menu.default = Filter::BAADER_MOON
    end
  end

  private def select_camera
    cli.choose do |menu|
      menu.prompt = 'What camera is used with this set?'
      Camera::ALL.each do |camera|
        menu.choice(camera)
      end
      menu.default = Camera::CANON_T7
    end
  end

  # TODO: Add menu to select for barlow/flatteners
  private def select_accessories; end

  # Checks for empty directories. Run this option after performing a move of previously
  # organized data.
  def remove_empty_directories
    puts 'Cleaning up empty directories...'
    is_dry_run = is_dry_run?
    Dir['**/*/.DS_Store'].each { |ds_store| FileUtils.rm ds_store, verbose: true, noop: is_dry_run }
    Dir['**/*/'].reverse_each { |d| FileUtils.rmdir d, verbose: true, noop: is_dry_run if (Dir.entries(d) - [".", ".."]).empty? }
  end

  # Removes all the jpg thumbnails under this directory.
  def remove_jpg_thumbnails
    puts 'Removing jpg thumbnails...'
    is_dry_run = is_dry_run?
    Dir['**/*_thn.jpg'].each { |jpg| FileUtils.rm jpg, verbose: true, noop: is_dry_run }
  end

  # Renames CR2 Raw files to match the same name pattern as ASIAir does based on EXIF data.
  def rename_from_exif
    type = cli.choose do |menu|
      menu.prompt = 'What is the file type?'
      Astrophoto::TYPES.each do |t|
        menu.choice(t)
      end
    end

    target = cli.ask('What is the target name?') if type == Astrophoto::LIGHT

    is_dry_run = is_dry_run?

    files = Dir['*.cr2', '*.CR2'].uniq
    if files.none? { |cr2| cr2.start_with?('IMG_') }
      cli.choose do |menu|
        menu.prompt = "Files (#{files.size}) are already named, e.g. #{files.first&.split(File::SEPARATOR)&.last}. What do?"
        menu.choice('Skip') { return }
        menu.choice('Proceed with rename (this cannot be undone) and continue') do
          # rename_to_img(files, is_dry_run)
        end
        menu.choice('Only rename back to IMG_****.cr2') do
          rename_to_img(files, is_dry_run)
          return
        end
      end
    end

    Dir['*.cr2', '*.CR2'].uniq.each do |cr2|
      exif = MiniExiftool.new(cr2)
      exif["SequenceNumber"] = exif.filename.split("_").last.split(".").first.to_i if exif["SequenceNumber"] == 0
      exif["Artist"] = "Joshua Kovach"
      exif.save
      exif.reload

      data = exif.to_hash

      exp_time = data["ExposureTime"]

      exp_unit = 's'
      if exp_time < 1.0
        exp_time *= 1000
        exp_unit = 'ms'
      end
      if exp_time < 1.0
        exp_time *= 1000
        exp_unit = 'us'
      end

      exp_time_str = format("%.1f%s", exp_time, exp_unit)

      created_at = data["DateTimeOriginal"].strftime(DT_FORMAT)
      ccd_temp = "%.1fC" % data["CameraTemperature"].to_f
      seq_num = data["SequenceNumber"].to_s.rjust(4, "0")
      cam_model = data["Model"]
      camera = Camera::ALL.find { |it| cam_model.include?(it) }
      if camera.nil?
        puts "Camera #{cam_model} did not match any of the expected models."
        camera = cli.choose do |menu|
          menu.prompt = "Choose an identifier for this camera:"
          cam_model.split(" ").each do |id|
            menu.choice(id)
          end
        end
      end

      target_file = "#{type}_#{target&.append("_")}#{exp_time_str}_Bin1_#{camera}_ISO#{data["ISO"]}_#{created_at}_#{ccd_temp}_#{seq_num}.CR2"

      FileUtils.move cr2, target_file, verbose: is_dry_run, noop: is_dry_run unless File.exist?(target_file)
      print "." unless is_dry_run
    end
    puts "Done"
  end

  def is_dry_run?
    cli.ask('Is this a dry run? [y/n]: ').downcase == 'y'
  end

  def rename_to_img(files, is_dry_run)
    files.each_with_index do |file, index|
      idx = (file.split(/[_-]/).last.to_i || index).to_s.rjust(4, "0")
      target_file = "IMG_#{idx}.CR2"
      puts "Renaming to #{target_file}"

      FileUtils.move file, target_file, verbose: is_dry_run, noop: is_dry_run unless File.exist?(target_file)
    end
  end

  # Prompts the user to choose which organizing task to run. This is the main entry point of
  # this script.
  def organize
    cli.choose do |menu|
      menu.prompt = 'What are we organizing?'

      menu.choice('Darks') do
        organize_darks
        organize
      end
      menu.choice('Flats') do
        organize_flats
        organize
      end
      menu.choice('Lights') do
        organize_lights
        organize
      end
      menu.choice('Biases') do
        organize_biases
        organize
      end
      menu.choice('Remove empty directories') do
        remove_empty_directories
        organize
      end
      menu.choice('Remove jpg thumbnails') do
        remove_jpg_thumbnails
        organize
      end
      menu.choice('Rename files from EXIF data') do
        rename_from_exif
        organize
      end
      menu.choice('Quit')
    end
  end
end

organizer = FitsOrganizer.new
organizer.organize
