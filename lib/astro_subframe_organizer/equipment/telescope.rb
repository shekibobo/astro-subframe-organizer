# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your telescopes to `~/astro-subframe-organizer-config.yml`. If there is more
    # than one, you will be prompted to choose one of them when organizing flats
    # and lights.
    class Telescope
      def self.all
        Config.all_telescopes
      end
    end
  end
end
