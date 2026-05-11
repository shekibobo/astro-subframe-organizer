# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your filters to `~/.astro-subframe-organizer.yml`. If there is more
    # than one, you will be prompted to choose one of them when organizing flats
    # and lights.
    class Filter
      def self.all
        Config.all_filters
      end
    end
  end
end
