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
      exts = (Config.fits_extensions + Config.raw_extensions).flat_map { |e| [e.downcase, e.upcase] }
      all = Dir.glob(exts.map { |e| "**/*#{e}" }, base: path)
      processable = all.filter { |it| !File.basename(it).match?(Utils::ExifRenamer::RAW_NAME_PATTERN) }
                       .uniq
                       .map { |relative| File.join(path, relative) }

      if processable.size != all.size
        unprocessable_raw_files_warning = 'Unprocessed raw images detected, but will be ignored. Raw images must be renamed before organizing. Run `astro-subframe-organizer raw rename_from_exif`, then try again.'
        logger.warn(unprocessable_raw_files_warning)
      end

      processable.map { |it| Astrophoto.new(it) }
    end

    def organize(dry_run: false)
      logger.info "Preparing to move #{file_sets.sum do |set|
        set.files.size
      end} #{type} files from #{file_sets.size} groups..."
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

        logger.info "For #{type} set #{fileset.files.first.filename}..#{fileset.files.last.filename}:"

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
      candidates = fileset.camera_candidates
      camera = if candidates.size > 1
                 logger.warn "Multiple cameras detected: #{candidates}"
                 equipment_selector.choose_camera
               else
                 equipment_selector.choose_camera_or_confirm(detected: candidates.first)
               end

      fileset.apply_camera!(camera)
    end

    def check_telescope(fileset)
      candidates = fileset.telescope_candidates
      telescope = if candidates.size > 1
                    logger.warn "Multiple telescopes detected: #{candidates}"
                    equipment_selector.choose_telescope
                  else
                    equipment_selector.choose_telescope_or_confirm(detected: candidates.first)
                  end

      fileset.apply_telescope!(telescope)
    end

    def check_filter(fileset)
      candidates = fileset.filter_candidates
      filter = if candidates.size > 1
                 logger.warn "Multiple filters detected: #{candidates}"
                 equipment_selector.choose_filter
               else
                 equipment_selector.choose_filter_or_confirm(detected: candidates.first)
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
