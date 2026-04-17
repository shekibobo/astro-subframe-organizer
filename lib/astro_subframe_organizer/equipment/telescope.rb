# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your telescopes here. You will be prompted to choose one of them when organizing flats and lights.
    class Telescope
      def self.all
        Config.all_telescopes
      end
    end
  end
end
