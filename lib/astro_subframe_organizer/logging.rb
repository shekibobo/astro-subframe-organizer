# frozen_string_literal: true

module AstroSubframeOrganizer
  # Mixin to provide logging capabilities to classes in the AstroSubframeOrganizer module.
  module Logging
    def logger
      AstroSubframeOrganizer.logger
    end
  end
end
