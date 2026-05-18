# frozen_string_literal: true

module AstroSubframeOrganizer
  # Main class responsible for interactively organizing FITS files based on their headers and user input.
  class FitsOrganizer
    include Logging

    private attr_accessor :prompt, :path, :dry_run

    def initialize(path = Dir.pwd, dry_run: nil)
      self.prompt = AstroSubframeOrganizer.prompt
      self.path = path
      self.dry_run = dry_run
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
        prompt: prompt,
      ).organize(dry_run: is_dry_run?)
    end

    def organize_biases
      Organizer.new(
        path: path,
        type: Astrophoto::BIAS,
        prompt: prompt,
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
        prompt: prompt,
      ).organize(dry_run: is_dry_run?)
    end

    # Organizes light files by FLATSET, ISO, BIN, EXP (EXPOSURE), TELESCOPE, and FILTER. To change these
    # properties, update Astrophoto#target_dir for the LIGHT type. The TELESCOPE and FILTER keywords are
    # for matching LIGHTS which will have the same keywords set when organized using this script.
    #
    # CCD-TEMP is included in the group naming using a rounded value to facilitate consistent keyword matching
    # in PixInsight WBPP, ensuring frames captured within a temperature range are grouped together.
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
        prompt: prompt,
      ).organize(dry_run: is_dry_run?)
    end

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
      type = prompt.enum_select('What is the file type?', Astrophoto::TYPES)
      target = prompt.ask('What is the target name?') if type == Astrophoto::LIGHT

      renamer.rename(type: type, target: target, dry_run: is_dry_run?)
    end

    def is_dry_run? # rubocop:disable Naming/PredicatePrefix
      dry_run.nil? ? prompt.yes?('Is this a dry run?', default: 'y') : dry_run
    end

    def rename_to_img
      renamer = Utils::ExifRenamer.new(path)
      renamer.revert(dry_run: is_dry_run?)
    end

    # Prompts the user to choose which organizing task to run. This is the main entry point of
    # this script.
    def organize
      loop do
        message = 'What are we organizing?'
        message += ' (Dry Run)' if dry_run

        choice = prompt.enum_select message, per_page: 8 do |menu|
          menu.choice 'Darks', :darks
          menu.choice 'Flats', :flats
          menu.choice 'Lights', :lights
          menu.choice 'Biases', :biases
          menu.choice 'Remove empty directories', :empty_dirs
          menu.choice 'Remove jpg thumbnails', :thumbnails
          menu.choice 'Rename files from EXIF data', :rename
          menu.choice 'Quit', :quit
        end

        case choice
        when :darks      then organize_darks
        when :flats      then organize_flats
        when :lights     then organize_lights
        when :biases     then organize_biases
        when :empty_dirs then remove_empty_directories
        when :thumbnails then remove_jpg_thumbnails
        when :rename     then rename_from_exif
        when :quit       then break
        end
      end
    end

    def self.run
      organizer = FitsOrganizer.new
      organizer.organize
    end

    private

    # TODO: Add menu to select for barlow/flatteners
    def select_accessories; end
  end
end
