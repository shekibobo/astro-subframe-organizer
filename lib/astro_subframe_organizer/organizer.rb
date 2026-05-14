# frozen_string_literal: true

module AstroSubframeOrganizer
  class Organizer
    include Logging

    attr_reader :file_sets, :type, :path, :equipment_selector
    protected attr_accessor :prompt

    def initialize(type:, path: Dir.pwd, prompt: AstroSubframeOrganizer.prompt, equipment_selector: nil)
      @prompt = prompt
      @path = path
      @type = type
      @file_sets = file_sets_for(type)
      @equipment_selector = equipment_selector || EquipmentSelector.new(prompt)
    end

    def fits_files
      all = Dir.glob(['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'], base: path)
      processable = all.filter { |it| !it.match?(/IMG_\d+.CR2$/) }
                       .uniq
                       .map { |relative| File.join(path, relative) }

      if processable.size != all.size
        unprocessable_raw_files_warning = 'Unprocessed raw images detected, but will be ignored. Raw images must be renamed before organizing. Run `astro-subframe-organizer raw rename_from_exif`, then try again.'
        logger.warn(unprocessable_raw_files_warning)
      end

      processable.map { |it| Astrophoto.new(it) }
    end

    def organize(dry_run: false)
      logger.info "Preparing to move #{file_sets.sum { |set| set.files.size }} #{type} files from #{file_sets.size} groups..."
      @file_sets.each do |fileset|
        next if fileset.already_moved?

        if fileset.all_unmoved?
          move = ENV['ASTRO_SUBFRAME_SKIP_CONFIRM'] == 'true' ||
                 prompt.yes?(
                   "Preparing to move #{fileset.size} #{fileset.type} file(s) \n  FROM #{relative_to_pwd(fileset.current_dir)} \n  TO   #{relative_to_pwd(fileset.files.first.target_dir)}\nContinue?",
                   default: 'y',
                 )
          next unless move
        end

        logger.info "For #{type} #{fileset.files.first.filename}..#{fileset.files.last.filename}:"

        check_telescope(fileset) if [Astrophoto::FLAT, Astrophoto::LIGHT].include?(type)
        check_filter(fileset) if [Astrophoto::FLAT, Astrophoto::LIGHT].include?(type)
        check_camera(fileset)

        require 'tty-progressbar'

        # Initialize the bar with the size of the fileset
        bar = TTY::ProgressBar.new('Moving files [:bar] :current/:total (:percent) :eta', total: fileset.size)

        fileset.each do |it|
          it.move(dry_run, bar)
          bar.advance(1) # Move the bar forward by 1 for each file
        end

        logger.info 'Done'
      end
    end

    private

    def file_sets_for(type)
      FileSet.from_files(fits_files, type: type)
    end

    def check_camera(fileset)
      camera = equipment_selector.camera

      unless camera
        cameras = fileset.camera_candidates
        camera = if cameras.empty?
                   logger.warn 'Camera auto-detect.'
                   equipment_selector.choose_camera
                 elsif cameras.size > 1
                   logger.warn "Multiple cameras detected: #{cameras}"
                   equipment_selector.choose_camera
                 else
                   cameras.first
                 end
      end

      fileset.apply_camera!(camera)
    end

    def check_telescope(fileset)
      telescope = equipment_selector.telescope

      unless telescope
        telescopes = fileset.telescope_candidates
        telescope = if telescopes.empty?
                      equipment_selector.choose_telescope_or_confirm(detected: nil)
                    elsif telescopes.size > 1
                      logger.warn "Multiple telescopes detected: #{telescopes}"
                      equipment_selector.choose_telescope
                    else
                      equipment_selector.choose_telescope_or_confirm(detected: telescopes.first)
                    end
      end

      fileset.apply_telescope!(telescope)
    end

    def check_filter(fileset)
      filter = equipment_selector.filter

      unless filter
        filters = fileset.filter_candidates
        filter = if filters.empty?
                   logger.warn 'Filter auto-detect failed.'
                   equipment_selector.choose_filter
                 elsif filters.size > 1
                   logger.warn "Multiple filters detected: #{filters}"
                   equipment_selector.choose_filter
                 else
                   filters.first
                 end
      end

      fileset.apply_filter!(filter)
    end

    def relative_to_pwd(path)
      relative = Pathname.new(path).relative_path_from(Dir.pwd).to_s
      relative.start_with?('..') ? path : relative
    rescue ArgumentError
      path # fallback to absolute path on different drives (Windows)
    end
  end
end
