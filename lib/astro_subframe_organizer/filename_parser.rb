# frozen_string_literal: true

module AstroSubframeOrganizer
  # Base class for parsing astrophotography filenames
  # Subclasses handle format-specific parsing (FITS, CR2, etc.)
  class FilenameParser
    DT_FORMAT = '%Y%m%d-%H%M%S'

    attr_reader :filename, :path

    def initialize(path)
      @path = path
      @filename = path.split('/').last
    end

    # Returns a hash of parsed metadata
    # Subclasses must implement this method
    def parse
      raise NotImplementedError, 'Subclasses must implement #parse'
    end

    # Factory method to create appropriate parser for a file
    def self.for_file(path)
      case File.extname(path).downcase
      when '.fit'
        FitsParser.new(path)
      when '.cr2'
        CR2Parser.new(path)
      else
        raise ArgumentError, "Unsupported file format: #{path}"
      end
    end

    protected

    def extract_base_name
      @filename.gsub(/\.(fit|FIT|cr2|CR2)$/, '')
    end

    def parse_parts(base_name)
      base_name.split('_')
    end
  end

  # Parser for FITS format files
  # Expected format: Type_Target_Exposure_Bin_Camera_ISO/Gain_DateTime_CCDTemp_ImageIndex
  class FitsParser < FilenameParser
    def parse
      base_name = extract_base_name
      parts = parse_parts(base_name)

      result = {}
      result[:type] = parts.shift
      result[:target] = parts.shift if result[:type] == 'Light'
      result[:mosaic_pane] = parts.shift if parts.first&.match?(/\A\d+-\d+\z/)
      result[:exposure] = parts.shift
      result[:bin] = parts.shift.gsub('Bin', '') if parts.first&.start_with?('Bin')
      result[:camera] = parts.shift if Camera::ALL.include?(parts.first)
      result[:iso] = parts.shift.gsub('ISO', '') if parts.first&.start_with?('ISO')
      result[:gain] = parts.shift.gsub('gain', '') if parts.first&.start_with?('gain')
      result[:created_at] = DateTime.strptime(parts.shift, DT_FORMAT)
      result[:ccd_temp] = parts.shift
      result[:image_index] = parts.shift

      result[:file_format] = :fits
      result[:path] = @path
      result[:filename] = @filename

      result
    end
  end

  # Parser for Canon CR2 format files
  # CR2 files typically have different metadata structure
  class CR2Parser < FilenameParser
    def parse
      base_name = extract_base_name
      parts = parse_parts(base_name)

      result = {}
      result[:type] = parts.shift
      result[:target] = parts.shift if result[:type] == 'Light'
      result[:mosaic_pane] = parts.shift if parts.first&.match?(/\A\d+-\d+\z/)
      result[:exposure] = parts.shift
      result[:bin] = parts.shift.gsub('Bin', '') if parts.first&.start_with?('Bin')
      result[:camera] = parts.shift if Camera::ALL.include?(parts.first)
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
