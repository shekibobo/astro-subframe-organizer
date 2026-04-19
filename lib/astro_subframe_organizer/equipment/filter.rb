# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your filters here. You will be prompted to choose one of them when organizing flats and lights.
    class Filter
      ALL = [
        BAADER_MOON = 'BaaderMoon',
        NBZ = 'NBZ',
        NONE = 'NoFilter',
      ].freeze
    end
  end
end
