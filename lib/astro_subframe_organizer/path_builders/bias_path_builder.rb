# frozen_string_literal: true

module AstroSubframeOrganizer
  module PathBuilders
    # Builds folder paths for bias (zero-exposure) calibration frames.
    #
    # Bias frames are organized by the following keywords, which allow WBPP to
    # automatically match biases during calibration of darks, flats, and lights:
    #
    #   Bias_ISO_<value>_EXP_<value>_Bin_<value>_CAMERA_<model>_MONTH_<YYYY-MM>
    #
    # **Keyword meanings:**
    # - ISO: Camera ISO setting
    # - EXP: Exposure time (typically 0.0s for bias frames)
    # - Bin: Binning mode
    # - CAMERA: Camera model
    # - MONTH: Year-Month in YYYY-MM format (used for seasonal grouping)
    #
    # Bias frames are primarily used as the baseline calibration for darks, flats, and lights
    # to remove electronic noise. WBPP uses these keywords to match an appropriate master bias
    # based on the ISO, exposure, binning, and season of acquisition.
    #
    # See README.md for details on the WBPP calibration workflow.
    class BiasPathBuilder < BasePathBuilder
      # @return [String] The folder path for this bias frame
      def build
        [
          'Bias',
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "CAMERA_#{@metadata.camera}",
          "MONTH_#{month}"
        ].compact.join('_')
      end
    end
  end
end
