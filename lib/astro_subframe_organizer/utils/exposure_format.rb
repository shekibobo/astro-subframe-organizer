# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    # Utility module to format exposure times in a human-readable way for path building and filename generation.
    module ExposureFormat
      # Formats an exposure time in seconds into a string with appropriate units (s, ms, or us).
      # @param exp_time [Numeric] The exposure time in seconds
      # @return [String] The formatted exposure time with units (e.g., "30.0s", "500.0ms", "250.0us")
      def format_exposure(exp_time)
        exp_time  = exp_time.to_f
        unit      = 's'
        if exp_time < 1.0
          exp_time *= 1000
          unit = 'ms'
        end
        if exp_time < 1.0
          exp_time *= 1000
          unit = 'us'
        end
        format('%<time>.1f%<unit>s', time: exp_time, unit: unit)
      end
    end
  end
end
