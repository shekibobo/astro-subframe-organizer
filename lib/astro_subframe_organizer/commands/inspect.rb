# lib/astro_subframe_organizer/commands/inspect.rb
# frozen_string_literal: true

require 'fits_parser'
require 'exiftool_vendored'

module AstroSubframeOrganizer
  module Commands
    class Inspect < Dry::CLI::Command
      include Logging

      desc 'Inspect FITS or RAW file headers'

      example [
        'path/to/file.fit       # inspect FITS headers',
        'path/to/file.cr2       # inspect CR2 EXIF data',
        'path/to/file.fit --raw # force EXIF output for a .fit file',
      ]

      argument :path, required: true, desc: 'Path to the .fit or .cr2 file to inspect'

      option :raw, type: :boolean, default: false, desc: 'Force EXIF output even for .fit files'

      def call(path:, raw: false, **)
        unless File.exist?(path)
          logger.error "File not found: #{path}"
          exit 1
        end

        ext = File.extname(path).downcase

        if ext == '.fit' && !raw
          print_fits_headers(path)
        elsif %w[.cr2 .cr3 .nef .arw .orf .raf].include?(ext) || raw
          print_exif_data(path)
        else
          logger.error "Unsupported file type: #{ext}"
          exit 1
        end
      end

      private

      def print_fits_headers(path)
        puts "FITS Headers: #{File.basename(path)}"
        puts '─' * 60

        hdus = FitsParser.new(path).parse_hdus
        hdu  = hdus.find { |h| h[:header] }

        unless hdu
          logger.error 'No HDU with headers found.'
          exit 1
        end

        hdu[:header].each do |key, value|
          next if value.nil?

          formatted_key   = key.ljust(10)
          formatted_value = format_fits_value(value)
          puts "#{formatted_key}  #{formatted_value.strip}"
        end
      end

      def print_exif_data(path)
        Exiftool.command = 'exiftool.exe' if Gem.win_platform?

        puts "EXIF Data: #{File.basename(path)}"
        puts '─' * 60

        exif = Exiftool.new(path).to_display_hash
        exif.reject { |_, v| v.nil? }
            .sort_by { |k, _| k }
            .each do |key, value|
              formatted_key   = key.ljust(30)
              formatted_value = format_exif_value(value)
              puts "#{formatted_key}  #{formatted_value.strip}"
            end
      end

      def format_fits_value(value)
        case value
        when true    then 'T'
        when false   then 'F'
        when Float   then format('%-20.10G', value)
        when Integer then value.to_s
        when String  then value
        else              value.to_s
        end
      end

      def format_exif_value(value)
        case value
        when Time, DateTime then value.strftime('%Y-%m-%d %H:%M:%S')
        when Float          then format('%.6G', value)
        when Array          then value.join(', ')
        else                     value.to_s
        end
      end
    end
  end
end
