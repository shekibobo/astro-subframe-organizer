# frozen_string_literal: true

module AstroSubframeOrganizer
  module FilenameParsers
    # Parser for Canon CR2 (Canon Raw 2) format files from ASIAir Plus.
    #
    # CR2 files are Canon RAW image files that can be captured by cameras like the Canon T7.
    # The filename structure is similar to FITS files when captured via ASIAir Plus.
    #
    # Expected filename format:
    #   Type_[Target]_[Mosaic]_Exposure_BinBinning_Camera_ISO/Gain_DateTime_CCDTemp_ImageIndex.cr2
    #
    # Example:
    #   Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.cr2
    #
    # Returns a hash with keys identical to FitsParser, except:
    #   - :file_format (:cr2 instead of :fits)
    #
    # The CR2 format uses CCD-TEMP instead of ISO for temperature tracking since RAW files
    # preserve more metadata from the camera hardware.
    class CR2Parser < FilenameParser
      # @return [Hash] Parsed metadata from CR2 filename
      def parse
        base_name = extract_base_name
        parts = parse_parts(base_name)

        result = {}
        result[:type] = parts.shift
        result[:target] = parts.shift if result[:type] == 'Light'
        result[:mosaic_pane] = parts.shift if parts.first&.match?(/\A\d+-\d+\z/)
        result[:exposure] = parts.shift
        result[:bin] = parts.shift.gsub('Bin', '') if parts.first&.start_with?('Bin')
        result[:camera] = parts.shift if Equipment::Camera::ALL.include?(parts.first)
        result[:iso] = parts.shift.gsub('ISO', '') if parts.first&.start_with?('ISO')
        result[:gain] = parts.shift.gsub('gain', '') if parts.first&.start_with?('gain')
        result[:created_at] = DateTime.strptime(parts.shift, DT_FORMAT)
        result[:ccd_temp] = parts.shift
        result[:image_index] = parts.shift

        result[:file_format] = :cr2
        result[:path] = @path
        result[:filename] = @filename

        result
      end
    end
  end
end
