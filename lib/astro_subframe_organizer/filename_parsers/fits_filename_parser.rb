# frozen_string_literal: true

module AstroSubframeOrganizer
  module FilenameParsers
    # Parser for FITS format files from ASIAir Plus.
    #
    # Expected filename format:
    #   Type_[Target]_[Mosaic]_Exposure_BinBinning_Camera_ISO/Gain_DateTime_CCDTemp_ImageIndex
    #
    # Example:
    #   Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit
    #   Dark_30.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit
    #
    # Returns a hash with keys:
    #   - :type (Light, Dark, Flat, Bias)
    #   - :target (for Light files only)
    #   - :mosaic_pane (optional, if present)
    #   - :exposure (with units, e.g., "1.0s")
    #   - :bin (numeric string)
    #   - :camera (model name)
    #   - :iso (numeric string, if present)
    #   - :gain (numeric string, if ISO not present)
    #   - :created_at (DateTime object)
    #   - :ccd_temp (with units, e.g., "-10.0C")
    #   - :image_index (numeric string)
    #   - :file_format (:fits)
    #   - :path (full file path)
    #   - :filename (just the filename)
    class FitsFilenameParser < FilenameParser
      include Logging

      # @return [Hash] Parsed metadata from FITS filename
      def parse
        base_name = extract_base_name
        parts = parse_parts(base_name)
        result = {}

        begin
          result[:file_format] = :fits
          result[:path] = @path
          result[:filename] = @filename

          # If the file is already organized somewhere, get the information from its path.
          result.merge!(extract_metadata_from_path)

          result[:type] = parts.shift
          result[:target] = parts.shift if result[:type] == 'Light'
          result[:mosaic_pane] = parts.shift if parts.first&.match?(/\A\d+-\d+\z/)
          result[:exposure] = parts.shift
          result[:bin] = parts.shift.gsub('Bin', '') if parts.first&.start_with?('Bin')
          result[:camera] = parts.shift if Equipment::Camera.all.include?(parts.first)
          result[:iso] = parts.shift.gsub('ISO', '') if parts.first&.start_with?('ISO')
          result[:gain] = parts.shift.gsub('gain', '') if parts.first&.start_with?('gain')
          result[:created_at] = DateTime.strptime(parts.shift, FILENAME_DT_FORMAT)
          result[:ccd_temp] = parts.shift
          result[:image_index] = parts.shift
        rescue StandardError => e
          logger.error e
        ensure
          logger.debug result
        end

        FileMetadata.from_parsed_data(result)
      end
    end
  end
end
