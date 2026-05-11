# frozen_string_literal: true

module AstroSubframeOrganizer
  module Utils
    # Strips image data and identifying location information from FITS files.
    # The resulting file is valid FITS with NAXIS set to 0, meaning no
    # data array follows the header block.
    #
    # Location headers stripped: SITELAT, SITELONG, SITEELEV, RA, DEC,
    # OBJCTRA, OBJCTDEC, CRVAL1, CRVAL2, CRPIX1, CRPIX2, and WCS keywords.
    class FitsStripper
      BLOCK_SIZE      = 2880
      CARD_SIZE       = 80
      CARDS_PER_BLOCK = BLOCK_SIZE / CARD_SIZE

      LOCATION_HEADERS = %w[
        SITELAT
        SITELONG
        SITEELEV
        RA
        DEC
        OBJCTRA
        OBJCTDEC
      ].freeze

      # WCS (World Coordinate System) headers that encode pointing information
      WCS_PREFIXES = %w[CRVAL CRPIX CD1_ CD2_ A_ B_ AP_ BP_ CTYPE CUNIT].freeze

      def self.strip(input_path, output_path = nil)
        new(input_path, output_path).strip
      end

      def initialize(input_path, output_path = nil)
        @input_path  = input_path
        @output_path = output_path || input_path # default to in-place
      end

      def already_stripped?
        File.open(@input_path, 'rb') do |f|
          loop do
            block = f.read(BLOCK_SIZE)
            return false unless block&.length == BLOCK_SIZE

            cards = block.scan(/.{#{CARD_SIZE}}/m)
            naxis_card = cards.find { |c| c.start_with?('NAXIS   =') }
            return naxis_card.match?(/=\s+0\b/) if naxis_card

            return false if header_end?(block)
          end
        end
        false
      end

      def strip
        header_blocks = read_header_blocks
        patched       = patch_naxis(header_blocks)
        patched       = strip_location_headers(patched)
        File.binwrite(@output_path, patched)
        @output_path
      end

      private

      def read_header_blocks
        blocks = []
        File.open(@input_path, 'rb') do |f|
          loop do
            block = f.read(BLOCK_SIZE)
            break unless block&.length == BLOCK_SIZE

            blocks << block
            break if header_end?(block)
          end
        end
        blocks.join
      end

      def patch_naxis(header_data)
        header_data.gsub(/NAXIS   =\s+\d+/) { |m| 'NAXIS   =                    0'.ljust(m.length) }
      end

      def strip_location_headers(header_data)
        cards = header_data.scan(/.{#{CARD_SIZE}}/m)
        cards.map do |card|
          if location_header?(card)
            blank_card
          else
            card
          end
        end.join
      end

      def location_header?(card)
        key = card[0, 8].strip
        LOCATION_HEADERS.include?(key) ||
          WCS_PREFIXES.any? { |prefix| key.start_with?(prefix) }
      end

      def blank_card
        ' ' * CARD_SIZE
      end

      def header_end?(block)
        block.scan(/.{#{CARD_SIZE}}/m).any? { |card| card.start_with?('END ') }
      end

      def stripped_path(input_path)
        dir      = File.dirname(input_path)
        basename = File.basename(input_path, '.*')
        ext      = File.extname(input_path)
        File.join(dir, "#{basename}_stripped#{ext}")
      end
    end
  end
end
