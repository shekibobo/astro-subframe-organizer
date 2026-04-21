# frozen_string_literal: true

module AstroSubframeOrganizer
  class EquipmentSelector
    include Equipment
    include Logging

    def initialize(telescopes: Telescope.all, cameras: Camera.all, filters: Filter.all, cli: CLI::UI::Prompt)
      @telescopes = telescopes
      @cameras = cameras
      @filters = filters
      @cli = cli
    end

    def choose_telescope(index = nil)
      if index && @telescopes[index]
        @telescopes[index]
      elsif @telescopes.one?
        @telescopes.first
      else
        choose('What telescope is this set for?', @telescopes)
      end.tap { |it| logger.info("Selected Telescope: #{it}") }
    end

    def choose_filter(index = nil)
      if index && @filters[index]
        @filters[index]
      elsif @filters.one?
        @filters.first
      else
        choose('What filter is used with this set?', @filters)
      end.tap { |it| logger.info("Selected Filter: #{it}") }
    end

    def choose_camera(index = nil)
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
      @cli.ask prompt, options: options
    end
  end
end
