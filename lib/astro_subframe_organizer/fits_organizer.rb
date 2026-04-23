# frozen_string_literal: true

require 'cli/ui/prompt'

module AstroSubframeOrganizer
  class FitsOrganizer
    include Logging

    private attr_accessor :cli, :path

    def initialize(path = Dir.pwd)
      self.cli = CLI::UI::Prompt
      self.path = path
    end

    def fits_files
      Dir.glob(['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'], base: path).uniq.map { |it| Astrophoto.new(it) }
    end

    private def equipment_selector
      @equipment_selector ||= EquipmentSelector.new(cli)
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
      Organizer.new(
        path: path,
        type: Astrophoto::DARK,
        cli: cli,
        equipment_selector: equipment_selector,
      ).organize(dry_run: is_dry_run?)
    end

    def organize_biases
      Organizer.new(
        path: path,
        type: Astrophoto::BIAS,
        cli: cli,
        equipment_selector: equipment_selector,
      ).organize(dry_run: is_dry_run?)
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
      Organizer.new(
        path: path,
        type: Astrophoto::FLAT,
        cli: cli,
        equipment_selector: equipment_selector,
      ).organize(dry_run: is_dry_run?)
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
      Organizer.new(
        path: path,
        type: Astrophoto::LIGHT,
        cli: cli,
        equipment_selector: equipment_selector,
      ).organize(dry_run: is_dry_run?)
    end

    # TODO: Add menu to select for barlow/flatteners
    private def select_accessories; end

    # Checks for empty directories. Run this option after performing a move of previously
    # organized data.
    def remove_empty_directories
      Utils::EmptyDirectoryCleaner.new(path).cleanup(dry_run: is_dry_run?)
    end

    # Removes all the jpg thumbnails under this directory.
    def remove_jpg_thumbnails
      Utils::ThumbnailCleaner.new(path).cleanup(dry_run: is_dry_run?)
    end

    # Renames CR2 Raw files to match the same name pattern as ASIAir does based on EXIF data.
    def rename_from_exif
      renamer = Utils::ExifRenamer.new(path)
      type = cli.ask('What is the file type?', options: Astrophoto::TYPES)
      target = cli.ask('What is the target name?') if type == Astrophoto::LIGHT

      renamer.rename(type: type, target: target, dry_run: is_dry_run?)
    end

    def is_dry_run?
      cli.confirm('Is this a dry run? [y/n]: ', default: 'y')
    end

    def rename_to_img(files, is_dry_run)
      files.each_with_index do |file, index|
        idx = (file.split(/[_-]/).last.to_i || index).to_s.rjust(4, '0')
        target_file = "IMG_#{idx}.CR2"
        logger.info "Renaming to #{target_file}"

        FileUtils.move file, target_file, verbose: is_dry_run, noop: is_dry_run unless File.exist?(target_file)
      end
    end

    # Prompts the user to choose which organizing task to run. This is the main entry point of
    # this script.
    def organize
      cli.ask 'What are we organizing?' do |menu|
        menu.option('Darks') do
          organize_darks
          organize
        end
        menu.option('Flats') do
          organize_flats
          organize
        end
        menu.option('Lights') do
          organize_lights
          organize
        end
        menu.option('Biases') do
          organize_biases
          organize
        end
        menu.option('Remove empty directories') do
          remove_empty_directories
          organize
        end
        menu.option('Remove jpg thumbnails') do
          remove_jpg_thumbnails
          organize
        end
        menu.option('Rename files from EXIF data') do
          rename_from_exif
          organize
        end
        menu.option('Quit') { exit }
      end
    end

    def self.run
      organizer = FitsOrganizer.new
      organizer.organize
    end
  end
end
