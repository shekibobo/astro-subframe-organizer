# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    module ExposureFormat
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
        format('%.1f%s', exp_time, unit)
      end
    end
  end
end
