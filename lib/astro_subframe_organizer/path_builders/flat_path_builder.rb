# frozen_string_literal: true

module AstroSubframeOrganizer
  module PathBuilders
    # Builds folder paths for flat field frames.
    #
    # Flat frames are organized by the following keywords, which allow WBPP to
    # automatically match flats to lights during the flat field calibration step:
    #
    #   Flat_FLATSET_<date>_ISO_<value>_EXP_<value>_Bin_<value>_TELESCOPE_<name>_FILTER_<name>_CAMERA_<model>
    #
    # **Keyword meanings:**
    # - FLATSET: Date-based grouping (typically the morning after lights were captured)
    # - ROTATION: Normalized rotation angle (module 180 to ignore meridian flip, only present if rotation is recorded in FITS)
    # - ISO: Camera ISO setting (if ISO is recorded, mutually exclusive with GAIN)
    # - GAIN: Camera gain setting (if gain is recorded, mutually exclusive with ISO)
    # - EXP: Exposure time (note: WBPP requires matching EXP on flats to lights in WBPP_Integration)
    # - Bin: Binning mode
    # - TELESCOPE: Optical equipment used (refractor, Newtonian, etc.)
    # - FILTER: Filter used (luminance, Ha, OIII, etc.)
    # - CAMERA: Camera model
    #
    # These flats are typically grouped together with their corresponding flat darks in the
    # same FLATSET directory so WBPP can load both in one step during the WBPP_Flats process.
    #
    # Important: After generating master flats in WBPP, remove the "EXP_*" segment from the
    # filename so that WBPP_Integration can automatically match them to lights. Keywords must
    # match exactly between files for WBPP to match them.
    #
    # See README.md for details on WBPP_Flats process icon and keyword matching.
    class FlatPathBuilder < BasePathBuilder
      # @return [String] The folder path for this flat frame
      def build
        [
          'Flat',
          "FLATSET_#{@metadata.flatset_id}",
          @metadata.normalized_rotation&.then { |r| "ROTATION_#{r}deg" },
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "TELESCOPE_#{@metadata.telescope || '????'}",
          "FILTER_#{@metadata.filter || '????'}",
          "CAMERA_#{@metadata.camera || '????'}",
        ].compact.join('_')
      end
    end
  end
end
