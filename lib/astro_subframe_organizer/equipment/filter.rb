# frozen_string_literal: true

module AstroSubframeOrganizer
  module Equipment
    # Add your filters here. You will be prompted to choose one of them when organizing flats and lights.
    class Filter
      def self.all
        Config.all_filters
      end
    end
  end
end
