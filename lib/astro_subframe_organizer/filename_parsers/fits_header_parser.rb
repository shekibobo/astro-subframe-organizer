# frozen_string_literal: true

require 'fits_parser'

module AstroSubframeOrganizer
  module FilenameParsers
    class FitsHeaderParser < FilenameParser
      include Logging

      HEADER_MAP = {
        telescope: 'TELESCOP',
        filter: 'FILTER',
        type: 'IMAGETYP',
        target: 'OBJECT',
        exposure: 'EXPOSURE',
        binning: 'XBINNING',
        camera: 'INSTRUME',
        gain: 'GAIN',
        date_obs: 'DATE-OBS',
        ccd_temp: 'CCD-TEMP',
      }.freeze

      ROTATION_HEADERS = %w[ROTATANG ANGLE POSANGLE ROTATOR ROTAT OBJCTROT CCDROTSA].freeze

      attr_reader :headers

      def initialize(path)
        super(path)
        @headers = load_headers(path)
      end

      def [](key)
        headers[key]
      end

      def parse
        result = {
          file_format: :fits,
          path: @path,
          filename: @filename,
          dark_flat: @path.include?('DarkFlat'),
        }

        result[:telescope]   = header(:telescope)
        result[:filter]      = header(:filter)
        result[:type]        = image_type
        result[:target]      = header(:target) if light_frame?
        result[:exposure]    = header(:exposure)
        result[:bin]         = header(:binning)
        result[:camera]      = header(:camera)
        result[:gain]        = header(:gain)
        result[:created_at]  = parse_date(header(:date_obs))
        result[:ccd_temp]    = header(:ccd_temp)
        result[:image_index] = parse_parts(extract_base_name).last
        result[:rotation]    = rotation_angle

        FileMetadata.from_parsed_data(result)
      rescue StandardError => e
        logger.error "Failed to parse FITS headers for #{@filename}: #{e.message}"
        FileMetadata.from_parsed_data(file_format: :fits, path: @path, filename: @filename)
      ensure
        logger.debug result
      end

      private

      def load_headers(path)
        hdus = FitsParser.new(path).parse_hdus
        hdu  = hdus.find { |h| h[:header] }
        raise "No HDU with headers found in #{path}" unless hdu

        hdu[:header]
      end

      def image_type
        header(:type)
      end

      def light_frame?
        image_type == Astrophoto::LIGHT
      end

      def header(key)
        headers[HEADER_MAP[key]]
      end

      def rotation_angle
        ROTATION_HEADERS.lazy.filter_map { |key| headers[key] }.first
      end

      def parse_date(value)
        return nil if value.nil?

        DateTime.strptime(value, '%Y-%m-%dT%H:%M:%S.%6N')
      rescue ArgumentError
        DateTime.parse(value)
      end
    end
  end
end
