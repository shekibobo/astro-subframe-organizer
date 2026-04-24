# frozen_string_literal: true

require 'fits_parser'

module AstroSubframeOrganizer
  module FilenameParsers
    class FitsHeaderParser < FilenameParser
      include Logging

      attr_reader :headers

      def initialize(path)
        super(path)

        @headers = FitsParser.new(path).headers
      end

      def [](key)
        headers[key]
      end

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
          result[:telescope] = headers['TELESCOP']
          result[:filter] = headers['FILTER']
          result[:type] = headers['IMAGETYP']
          result[:target] = headers['OBJECT'] if result[:type] == 'Light'

          result[:dark_flat] = path.include?('DarkFlat')

          # result[:mosaic_pane] = parts.shift if parts.first&.match?(/\A\d+-\d+\z/)
          result[:exposure] = headers['EXPOSURE']
          result[:bin] = headers['BIN']
          result[:camera] = headers['INSTRUME']
          result[:iso] = headers['ISO']
          result[:gain] = headers['GAIN']
          result[:created_at] = DateTime.strptime(headers['DATE-OBS'], DT_FORMAT)
          result[:ccd_temp] = headers['CCD-TEMP']
          result[:image_index] = parts.last
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
