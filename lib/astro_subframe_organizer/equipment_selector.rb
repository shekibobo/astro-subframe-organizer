# frozen_string_literal: true

module AstroSubframeOrganizer
  class EquipmentSelector
    include Equipment
    include Logging

    attr_accessor :telescope, :camera, :filter

    def initialize(prompt = AstroSubframeOrganizer.prompt, telescopes: Telescope.all, cameras: Camera.all, filters: Filter.all)
      @telescopes = telescopes
      @cameras = cameras
      @filters = filters
      @prompt = prompt
    end

    def choose_telescope(index = nil)
      return telescope if telescope

      if index && @telescopes[index]
        @telescopes[index]
      elsif @telescopes.one?
        @telescopes.first
      else
        choose('What telescope is this set for?', @telescopes)
      end.tap { |it| logger.info("Selected Telescope: #{it}") }
    end

    def choose_telescope_or_confirm(detected:)
      if telescope
        logger.warn "Using telescope #{telescope}, but detected #{detected}" if detected && telescope != detected
        return telescope
      end

      if detected && @telescopes.include?(detected)
        # Header value matches a known telescope — use it directly
        detected
      elsif detected
        # Header has a value but it's not in the configured list (e.g. "EQMod Mount")
        logger.warn "TELESCOP header '#{detected}' is not in the configured telescope list."
        choose(
          "TELESCOP is '#{detected}' — select the actual telescope or confirm:",
          [detected] + @telescopes,
        ).tap { |it| logger.info("Selected Telescope: #{it}") }
      else
        # No header value at all
        logger.warn 'Telescope auto-detect failed.'
        choose_telescope
      end
    end

    def choose_camera_or_confirm(detected:)
      if camera
        logger.warn "Using camera #{camera}, but detected #{detected}" if detected && camera != detected
        return camera
      end

      if detected && @cameras.include?(detected)
        detected
      elsif detected
        logger.warn "INSTRUME header '#{detected}' is not in the configured camera list."
        choose(
          "INSTRUME is '#{detected}' — select the actual camera or confirm:",
          [detected] + @cameras,
        ).tap { |it| logger.info("Selected Camera: #{it}") }
      else
        logger.warn 'Camera auto-detect failed.'
        choose_camera
      end
    end

    def choose_filter(index = nil)
      return filter if filter

      if index && @filters[index]
        @filters[index]
      elsif @filters.one?
        @filters.first
      else
        choose('What filter is used with this set?', @filters)
      end.tap { |it| logger.info("Selected Filter: #{it}") }
    end

    def choose_filter_or_confirm(detected:)
      if filter
        logger.warn "Using filter #{filter}, but detected #{detected}" if detected && filter != detected
        return filter
      end

      if detected && @filters.include?(detected)
        detected
      elsif detected
        logger.warn "FILTER header '#{detected}' is not in the configured filter list."
        choose(
          "FILTER is '#{detected}' — select the actual filter or confirm:",
          [detected] + @filters,
        ).tap { |it| logger.info("Selected Filter: #{it}") }
      else
        logger.warn 'Filter auto-detect failed.'
        choose_filter
      end
    end

    def choose_camera(index = nil)
      return camera if camera

      if index && @cameras[index]
        @cameras[index]
      elsif @cameras.one?
        @cameras.first
      else
        choose('What camera is used with this set?', @cameras)
      end.tap { |it| logger.info("Selected Camera: #{it}") }
    end

    private

    def choose(prompt, options)
      @prompt.enum_select prompt, options
    end
  end
end
