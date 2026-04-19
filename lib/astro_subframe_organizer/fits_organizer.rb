# frozen_string_literal: true

module AstroSubframeOrganizer
  class FitsOrganizer
    include Logging

    private attr_accessor :cli

    def initialize
      self.cli = CLI::UI::Prompt
    end

    def fits_files
      Dir['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'].uniq.map { |it| Astrophoto.new(it) }
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
        files: fits_files,
        type: Astrophoto::DARK,
        cli: cli,
        equipment_selector: equipment_selector,
      ).organize(dry_run: is_dry_run?)
    end

    def organize_biases
      Organizer.new(
        files: fits_files,
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
        files: fits_files,
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
        files: fits_files,
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
      logger.info 'Cleaning up empty directories...'
      is_dry_run = is_dry_run?
      Dir['**/*/.DS_Store'].each { |ds_store| FileUtils.rm ds_store, verbose: true, noop: is_dry_run }
      Dir['**/*/'].reverse_each { |d| FileUtils.rmdir d, verbose: true, noop: is_dry_run if (Dir.entries(d) - ['.', '..']).empty? }
    end

    # Removes all the jpg thumbnails under this directory.
    def remove_jpg_thumbnails
      logger.info 'Removing jpg thumbnails...'
      is_dry_run = is_dry_run?
      Dir['**/*_thn.jpg'].each { |jpg| FileUtils.rm jpg, verbose: true, noop: is_dry_run }
    end

    # Renames CR2 Raw files to match the same name pattern as ASIAir does based on EXIF data.
    def rename_from_exif
      type = cli.ask('What is the file type?', options: Astrophoto::TYPES)
      target = cli.ask('What is the target name?') if type == Astrophoto::LIGHT

      is_dry_run = is_dry_run?

      files = Dir['*.cr2', '*.CR2'].uniq
      if files.none? { |cr2| cr2.start_with?('IMG_') }
        cli.ask "Files (#{files.size}) are already named, e.g. #{files.first&.split(File::SEPARATOR)&.last}. What do?" do |menu|
          menu.option('Skip') { return }
          menu.option('Proceed with rename (this cannot be undone) and continue') do
            # rename_to_img(files, is_dry_run)
          end
          menu.option('Only rename back to IMG_****.cr2') do
            rename_to_img(files, is_dry_run)
            return
          end
        end
      end

      Dir['*.cr2', '*.CR2'].uniq.each do |cr2|
        exif = MiniExiftool.new(cr2)
        exif['SequenceNumber'] = exif.filename.split('_').last.split('.').first.to_i if exif['SequenceNumber'] == 0
        exif['Artist'] = 'Joshua Kovach'
        exif.save
        exif.reload

        data = exif.to_hash

        exp_time = data['ExposureTime']

        exp_unit = 's'
        if exp_time < 1.0
          exp_time *= 1000
          exp_unit = 'ms'
        end
        if exp_time < 1.0
          exp_time *= 1000
          exp_unit = 'us'
        end

        exp_time_str = format('%.1f%s', exp_time, exp_unit)

        created_at = data['DateTimeOriginal'].strftime(DT_FORMAT)
        ccd_temp = format('%.1fC', data['CameraTemperature'].to_f)
        seq_num = data['SequenceNumber'].to_s.rjust(4, '0')
        cam_model = data['Model']
        camera = OrganizeAstroData::Camera.all.find { |it| cam_model.include?(it) }
        if camera.nil?
          logger.warn "Camera #{cam_model} did not match any of the expected models."
          camera = cli.ask 'Choose an identifier for this camera:', options: cam_model.split(' ')
        end

        target_file = [type, target, exp_time_str, 'Bin1', camera, "ISO#{data['ISO']}", created_at, ccd_temp, seq_num].compact.join('_') + '.CR2'
        # target_file = "#{type}_#{target&.append("_")}#{exp_time_str}_Bin1_#{camera}_ISO#{data["ISO"]}_#{created_at}_#{ccd_temp}_#{seq_num}.CR2"

        FileUtils.move cr2, target_file, verbose: is_dry_run, noop: is_dry_run unless File.exist?(target_file)
        print '.' unless is_dry_run
      end
      logger.info 'Done'
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
      cli.ask 'What are we organizing' do |menu|
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
