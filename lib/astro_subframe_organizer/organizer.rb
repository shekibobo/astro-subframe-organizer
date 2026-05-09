# frozen_string_literal: true

module AstroSubframeOrganizer
  class Organizer
    include Logging

    attr_reader :file_sets, :type, :path, :equipment_selector
    protected attr_accessor :cli

    def initialize(type:, path: Dir.pwd, cli: CLI::UI::Prompt, equipment_selector: nil)
      @cli = cli
      @path = path
      @type = type
      @file_sets = file_sets_for(type)
      @equipment_selector = equipment_selector || EquipmentSelector.new(cli)
    end

    def fits_files
      Dir.glob(['**/*.fit', '**/*.FIT', '**/*.cr2', '**/*.CR2'], base: path)
         .uniq
         .map { |relative| File.join(path, relative) }
         .map { |it| Astrophoto.new(it) }
    end

    def organize(dry_run: false)
      logger.info "Preparing to move #{file_sets.sum { |set| set.files.size }} #{type} files..."
      @file_sets.each do |fileset|
        next if fileset.already_moved?

        if fileset.all_unmoved?
          move = ENV['ASTRO_SUBFRAME_SKIP_CONFIRM'] == 'true' ||
                 cli.confirm("Do you want to move the #{fileset.type} files in #{fileset.current_dir} to #{fileset.files.first.target_dir}? [y/n] ", default: 'y')
          next unless move
        end

        logger.info "For #{type} #{fileset.files.first.filename}..#{fileset.files.last.filename}:"

        check_telescope(fileset) if [Astrophoto::FLAT, Astrophoto::LIGHT].include?(type)
        check_filter(fileset) if [Astrophoto::FLAT, Astrophoto::LIGHT].include?(type)
        check_camera(fileset)

        fileset.each { |it| it.move(dry_run) }
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
                   logger.warn 'Camera not detected.'
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
                      logger.warn 'Telescope not detected.'
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
                   logger.warn 'Filter not detected.'
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
  end
end
