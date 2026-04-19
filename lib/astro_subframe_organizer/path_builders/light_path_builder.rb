# frozen_string_literal: true

module AstroSubframeOrganizer
  module PathBuilders
    # Builds folder paths for light (science) frames.
    #
    # Light frames are organized by the following keywords, which allow WBPP to
    # automatically match lights to calibration frames (darks and flats) during integration:
    #
    # **FITS files:**
    #   Light_<target>_PANE_<pane>_FLATSET_<date>_ISO_<value>_EXP_<value>_Bin_<value>_TELESCOPE_<name>_FILTER_<name>_CAMERA_<model>
    #
    # **CR2 (Canon RAW) files:**
    #   Light_<target>_PANE_<pane>_FLATSET_<date>_ISO_<value>_EXP_<value>_Bin_<value>_CCD-TEMP_<value>_TELESCOPE_<name>_FILTER_<name>_CAMERA_<model>
    #
    # **Keyword meanings:**
    # - Target: Object being imaged (e.g., M42, NGC1977)
    # - PANE: Mosaic pane identifier (e.g., 1-1, 1-2) - optional
    # - FLATSET: Date-based grouping matching the flats/darks captured for this light set
    # - ISO: Camera ISO setting (must match darks and flats)
    # - EXP: Exposure time (must match darks and flats)
    # - Bin: Binning mode (must match darks and flats)
    # - CCD-TEMP: CCD temperature (CR2 only; WBPP matches +/- 1°C for darks)
    # - TELESCOPE: Optical equipment used
    # - FILTER: Filter used
    # - CAMERA: Camera model
    #
    # The keywords are used by WBPP_Integration to automatically select matching darks,
    # flats, and biases for each light frame during the calibration and integration process.
    #
    # See README.md for details on WBPP_Integration process icon and keyword matching.
    class LightPathBuilder < BasePathBuilder
      # @return [String] The folder path for this light frame
      def build
        pane_segment = @metadata.mosaic_pane ? "_PANE_#{@metadata.mosaic_pane}" : ''
        prefix = "Light_#{@metadata.target}#{pane_segment}"

        case @metadata.file_format
        when :fits
          build_fits_path(prefix)
        when :cr2
          build_cr2_path(prefix)
        else
          raise ArgumentError, "Unsupported format: #{@metadata.file_format}"
        end
      end

      private

      def build_fits_path(prefix)
        [
          prefix,
          "FLATSET_#{flatset_id}",
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "TELESCOPE_#{@metadata.telescope}",
          "FILTER_#{@metadata.filter}",
          "CAMERA_#{@metadata.camera}",
        ].compact.join('_')
      end

      def build_cr2_path(prefix)
        [
          prefix,
          "FLATSET_#{flatset_id}",
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "CCD-TEMP_#{@metadata.ccd_temp.gsub('0C', '')}",
          "TELESCOPE_#{@metadata.telescope}",
          "FILTER_#{@metadata.filter}",
          "CAMERA_#{@metadata.camera}",
        ].compact.join('_')
      end
    end
  end
end
