# frozen_string_literal: true

module AstroSubframeOrganizer
  module PathBuilders
    # Builds folder paths for dark calibration frames.
    #
    # Dark frames are organized into folders by the following keywords, which allow WBPP
    # to automatically match darks to lights during calibration:
    #
    # **Normal Darks:**
    #   - Dark_ISO_<value>_EXP_<value>_CCD-TEMP_<value>_CAMERA_<model>_MONTH_<YYYY-MM>
    #
    #   These keywords enable matching darks to lights based on ISO, exposure time, CCD
    #   temperature, and the season (month) when captured. Temperature matching in WBPP
    #   allows for +/- 1°C variation to accommodate uncooled cameras.
    #
    # **Flat Darks (short exposure darks < 10 seconds):**
    #   - DarkFlat_FLATSET_<date>_ISO_<value>_EXP_<value>_Bin_<value>_CAMERA_<model>
    #
    #   Flat darks are grouped with their corresponding flat set using the FLATSET keyword.
    #   Temperature is not included since flats and flat darks are captured at roughly the
    #   same time under similar conditions. These are organized together so WBPP can load
    #   them as a unit during the flat field calibration step.
    #
    # See README.md for details on WBPP_Darks and WBPP_Flats process icons.
    class DarkPathBuilder < BasePathBuilder
      # @return [String] The folder path for this dark frame
      def build
        if @metadata.dark_flat?
          build_flat_dark_path
        else
          build_normal_dark_path
        end
      end

      private

      def build_normal_dark_path
        [
          'Dark',
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "CCD-TEMP_#{@metadata.rounded_ccd_temp}",
          "CAMERA_#{@metadata.camera || '????'}",
          "MONTH_#{@metadata.month}",
        ].compact.join('_')
      end

      def build_flat_dark_path
        [
          'DarkFlat',
          "FLATSET_#{@metadata.flatset_id}",
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "CAMERA_#{@metadata.camera || '????'}",
        ].compact.join('_')
      end
    end
  end
end
