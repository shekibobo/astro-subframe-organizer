# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your filters to `~/astro-subframe-organizer-config.yml`. If there is more
    # than one, and no camera is automatically detected, you will be prompted
    # to choose one of them when organizing subframes.
    class Camera
      def self.all
        Config.all_cameras
      end
    end
  end
end
