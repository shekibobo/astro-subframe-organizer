# frozen_string_literal: true

require 'fits_parser'

module AstroSubframeOrganizer
  module FilenameParsers
    class FitsHeaderParser < FilenameParser
      include Logging
      include AstroSubframeOrganizer::Utils::ExposureFormat

      HEADER_MAP = {
        telescope: 'TELESCOP',
        filter: 'FILTER',
        type: 'IMAGETYP',
        target: 'OBJECT',
        exposure: 'EXPOSURE',
        binning: 'XBINNING',
        camera: 'INSTRUME',
        gain: 'GAIN',
        iso: 'ISO',
        date_obs: 'DATE-OBS',
        ccd_temp: 'CCD-TEMP',
      }.freeze

      ROTATION_HEADERS = %w[ROTATANG ANGLE POSANGLE ROTATOR ROTAT OBJCTROT CCDROTSA].freeze

      def headers
        @headers ||= load_headers(path)
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

        # If the file is already organized somewhere, get the information from its path.
        result[:telescope] = path.match(%r{TELESCOPE_([^_/]+).*})&.captures&.first || header(:telescope)
        result[:filter] = path.match(%r{FILTER_([^_/]+).*})&.captures&.first || header(:filter)
        result[:dark_flat] = path.include?('DarkFlat')

        result[:type]        = image_type
        result[:target]      = target if light_frame?
        result[:exposure]    = format_exposure(header(:exposure))
        result[:bin]         = header(:binning)
        result[:camera]      = header(:camera)
        result[:gain]        = header(:gain)
        result[:iso]         = header(:iso)
        result[:created_at]  = parse_date(header(:date_obs))
        result[:ccd_temp]    = format_temp(header(:ccd_temp))
        result[:image_index] = parse_parts(extract_base_name).last
        result[:rotation]    = rotation_angle
        result[:mosaic_pane] = mosaic_pane

        FileMetadata.from_parsed_data(result)
      rescue StandardError => e
        logger.error "Failed to parse FITS headers for #{@filename}: #{e.message}"
        FileMetadata.from_parsed_data(file_format: :fits, path: @path, filename: @filename)
      ensure
        logger.debug result
      end

      def target
        headers[HEADER_MAP[:target]] || parsed_from_filename[:target]
      end

      def mosaic_pane
        # Not available in FITS headers for ASIAIR mosaic frames.
        # Must be parsed from filename pattern: TARGET_ROW-COL_
        parsed_from_filename[:mosaic_pane]
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

      private

      def load_headers(path)
        hdus = FitsParser.new(path).parse_hdus
        hdu  = hdus.find { |h| h[:header] }
        raise "No HDU with headers found in #{path}" unless hdu

        hdu[:header]
      end

      def parse_date(value)
        return nil if value.nil?

        DateTime.strptime(value, '%Y-%m-%dT%H:%M:%S.%6N')
      rescue ArgumentError
        DateTime.parse(value)
      end

      def parsed_from_filename
        @parsed_from_filename ||= begin
          parts = File.basename(@path, '.*').split('_')
          pane_index = parts.index { |p| p.match?(/\A\d{1,2}-\d{1,2}\z/) }
          {
            target: pane_index ? parts[1...pane_index].join('_') : nil,
            mosaic_pane: pane_index ? parts[pane_index] : nil,
          }
        end
      end

      def format_temp(temp)
        format '%0.1fC', temp
      end
    end
  end
end
