# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your cameras here. If there is no camera chosen, it will prompt you to choose one.
    class Camera
      def self.all
        Config.all_cameras
      end
    end
  end
end
