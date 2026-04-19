# frozen_string_literal: true

module AstroSubframeOrganizer
  class FitsOrganizer
    include Logging

    private attr_accessor :cli

    def initialize
      self.cli = HighLine.new
    end

    def fits_files
      Dir['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'].uniq.map { |it| Astrophoto.new(it) }
    end

    private def file_sets_for(type)
      FileSet.from_files(fits_files, type: type)
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
      dark_sets = file_sets_for(Astrophoto::DARK)
      logger.info "Preparing to move #{dark_sets.sum { |set| set.files.size }} DARK files..."

      is_dry_run = is_dry_run?

      dark_sets.each do |darkset|
        next if darkset.already_moved?

        if darkset.all_unmoved?
          move = cli.ask("Do you want to move the darkset in #{darkset.current_dir} to #{darkset.files.first.target_dir}? [y/n] ").downcase == 'y'
          next unless move
        end

        if darkset.maybe_flat_dark? &&
           cli.ask("Is this a flat dark set (size #{darkset.files.size})? [y/n] #{darkset.files.first.filename}: ").downcase == 'y'
          logger.info "Cool, we'll move that set to a FLATSET directory..."

          darkset.mark_dark_flat!
        end

        cameras = darkset.camera_candidates
        camera = if cameras.empty?
                   logger.warn 'Camera not detected.'
                   equipment_selector.choose_camera
                 elsif cameras.size > 1
                   logger.warn "Multiple cameras detected: #{cameras}"
                   equipment_selector.choose_camera
                 else
                   cameras.first
                 end

        darkset.apply_camera!(camera)
        darkset.each { |it| it.move(is_dry_run) }
        puts "Done\n"
      end
    end

    def organize_biases
      bias_sets = file_sets_for(Astrophoto::BIAS)
      logger.info "Preparing to move #{bias_sets.sum { |set| set.files.size }} BIAS files..."

      is_dry_run = is_dry_run?

      bias_sets.each do |biases|
        next if biases.already_moved?

        if biases.all_unmoved?
          move = cli.ask("Do you want to move the bias set in #{biases.current_dir} to #{biases.files.first.target_dir}? [y/n] ").downcase == 'y'
          next unless move
        end

        cameras = biases.camera_candidates
        camera = if cameras.empty?
                   logger.warn 'Camera not detected.'
                   equipment_selector.choose_camera
                 elsif cameras.size > 1
                   logger.warn "Multiple cameras detected: #{cameras}"
                   equipment_selector.choose_camera
                 else
                   cameras.first
                 end

        biases.apply_camera!(camera)
        biases.each { |it| it.move(is_dry_run) }
        puts "Done\n"
      end
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
      flat_sets = file_sets_for(Astrophoto::FLAT)
      logger.info "Preparing to move #{flat_sets.sum { |set| set.files.size }} FLAT files..."

      is_dry_run = is_dry_run?

      flat_sets.each do |flatset|
        next if flatset.already_moved?

        if flatset.all_unmoved?
          move = cli.ask("Do you want to move the flatset in #{flatset.current_dir} to #{flatset.files.first.target_dir}? [y/n] ").downcase == 'y'
          next unless move
        end

        logger.info "For FLATSET #{flatset.files.first.filename}..#{flatset.files.last.filename}:"
        telescope = equipment_selector.choose_telescope
        filter = equipment_selector.choose_filter
        cameras = flatset.camera_candidates
        camera = if cameras.empty?
                   logger.warn 'Camera not detected.'
                   equipment_selector.choose_camera
                 elsif cameras.size > 1
                   logger.warn "Multiple cameras detected: #{cameras}"
                   equipment_selector.choose_camera
                 else
                   cameras.first
                 end

        flatset.apply_telescope!(telescope)
        flatset.apply_filter!(filter)
        flatset.apply_camera!(camera)
        flatset.each { |it| it.move(is_dry_run) }
        puts "Done\n"
      end
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
      light_sets = file_sets_for(Astrophoto::LIGHT)
      logger.info "Preparing to move #{light_sets.sum { |set| set.files.size }} LIGHT files..."

      is_dry_run = is_dry_run?

      light_sets.each do |lightset|
        next if lightset.already_moved?

        if lightset.all_unmoved?
          move = cli.ask("Do you want to move the light set in #{lightset.current_dir} to #{lightset.files.first.target_dir}? [y/n] ").downcase == 'y'
          next unless move
        end

        logger.info "For LIGHTS #{lightset.files.first.filename}..#{lightset.files.last.filename}:"
        telescope = equipment_selector.choose_telescope
        filter = equipment_selector.choose_filter
        cameras = lightset.camera_candidates
        camera = if cameras.empty?
                   logger.warn 'Camera not detected.'
                   equipment_selector.choose_camera
                 elsif cameras.size > 1
                   logger.warn "Multiple cameras detected: #{cameras}"
                   equipment_selector.choose_camera
                 else
                   cameras.first
                 end

        lightset.apply_telescope!(telescope)
        lightset.apply_filter!(filter)
        lightset.apply_camera!(camera)
        lightset.each { |it| it.move(is_dry_run) }
        puts "Done\n"
      end
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
          camera = cli.choose do |menu|
            menu.prompt = 'Choose an identifier for this camera:'
            cam_model.split(' ').each do |id|
              menu.choice(id)
            end
          end
        end

        target_file = [type, target, exp_time_str, 'Bin1', camera, "ISO#{data['ISO']}", created_at, ccd_temp, seq_num].compact.join('_') + '.CR2'
        # target_file = "#{type}_#{target&.append("_")}#{exp_time_str}_Bin1_#{camera}_ISO#{data["ISO"]}_#{created_at}_#{ccd_temp}_#{seq_num}.CR2"

        FileUtils.move cr2, target_file, verbose: is_dry_run, noop: is_dry_run unless File.exist?(target_file)
        print '.' unless is_dry_run
      end
      puts "Done\n"
    end

    def is_dry_run?
      cli.ask('Is this a dry run? [y/n]: ').downcase == 'y'
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

    def self.run
      organizer = FitsOrganizer.new
      organizer.organize
    end
  end
end
