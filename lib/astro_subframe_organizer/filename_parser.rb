# frozen_string_literal: true

require 'forwardable'

module AstroSubframeOrganizer
  # Base class for parsing astrophotography filenames.
  #
  # This class uses the Strategy pattern to handle format-specific filename parsing.
  # The factory method `for_file` creates the appropriate parser subclass based on file extension.
  #
  # Subclasses must implement the `parse` method, which returns a hash of metadata keys
  # extracted from the filename.
  #
  # **Usage:**
  #   parser = FilenameParser.for_file('/path/to/Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
  #   metadata_hash = parser.parse
  #
  # See FitsFilenameParser and CR2FilenameParser for format-specific implementations.
  class FilenameParser
    extend Forwardable

    attr_reader :filename, :path, :result

    def_delegators :result,
                   :type,
                   :exposure,
                   :bin,
                   :camera,
                   :gain,
                   :iso,
                   :created_at,
                   :ccd_temp,
                   :image_index,
                   :telescope,
                   :filter,
                   :target,
                   :dark_flat,
                   :mosaic_pane

    def initialize(path)
      @path = path
      @filename = File.basename(path)
    end

    # Returns a hash of parsed metadata.
    #
    # Subclasses must implement this method.
    #
    # @return [FileMetadata] Parsed metadata with attributes like :type, :target, :exposure, etc.
    # @raise [NotImplementedError] If not implemented by subclass
    def parse
      raise NotImplementedError, 'Subclasses must implement #parse'
    end

    # Factory method to create the appropriate parser for a file.
    #
    # Determines the correct parser based on file extension (.fit or .cr2).
    # Case-insensitive for file extensions.
    #
    # @param path [String] Full path to the image file
    # @return [FitsFilenameParser, CR2FilenameParser] Appropriate parser instance
    # @raise [ArgumentError] If file format is not supported
    def self.for_file(path, use_headers: true)
      ext = File.extname(path).downcase
      if Config.fits_extensions.include?(ext)
        if use_headers
          FilenameParsers::FitsHeaderParser.new(path)
        else
          FilenameParsers::FitsFilenameParser.new(path)
        end
      elsif Config.raw_extensions.include?(ext)
        FilenameParsers::CR2FilenameParser.new(path)
      else
        raise ArgumentError, "Unsupported file format: #{path}"
      end
    end

    protected

    # Extracts metadata often embedded in the directory structure.
    #
    # @return [Hash] Metadata found in path (telescope, filter, dark_flat)
    def extract_metadata_from_path
      {
        telescope: path.match(%r{TELESCOPE_([^_/\\]+).*})&.captures&.first,
        filter: path.match(%r{FILTER_([^_/\\]+).*})&.captures&.first,
        dark_flat: path.match?(/DarkFlat/i),
      }
    end

    # Removes file extension from filename.
    #
    # @return [String] Filename without extension
    def extract_base_name
      File.basename(@filename, '.*')
    end

    # Splits filename into parts separated by underscores.
    #
    # @param base_name [String] Filename without extension
    # @return [Array<String>] Parts of the filename
    def parse_parts(base_name)
      base_name.split('_')
    end
  end
end
