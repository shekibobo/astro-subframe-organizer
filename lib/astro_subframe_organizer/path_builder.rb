# frozen_string_literal: true

module AstroSubframeOrganizer
  # Factory for creating and using path builders.
  #
  # This class serves as the entry point for building folder paths for astrophotography
  # image files. It uses the Strategy pattern to delegate path construction to specialized
  # builder classes based on the image file type (Dark, Flat, Light, or Bias).
  #
  # The resulting folder paths contain keywords that facilitate automatic file matching in
  # PixInsight's WeightedBatchPreProcessing (WBPP) script during calibration and integration.
  #
  # **Usage:**
  #   path = PathBuilder.build_for(photo_metadata)        # => "Dark_ISO_100_EXP_30.0s_..."
  #   full_path = PathBuilder.target_path_for(metadata)   # => "Dark_ISO_100_.../filename.fit"
  #
  # See the individual builder classes for details on keyword structure for each file type:
  # - DarkPathBuilder for dark calibration frames
  # - FlatPathBuilder for flat field frames
  # - LightPathBuilder for science (light) frames
  # - BiasPathBuilder for bias (zero-exposure) frames
  #
  # See README.md for details on the WBPP calibration workflow and keyword matching.
  class PathBuilder
    # Builds the folder path for an image based on its type and metadata.
    #
    # @param metadata [Object] Image metadata object (typically an Astrophoto instance)
    #                  Must respond to: type, dark_flat?, file_format
    # @return [String] The folder path with WBPP-compatible keywords
    # @raise [ArgumentError] If the image type is not supported
    def self.build_for(metadata)
      builder = case metadata.type
                when 'Dark'
                  PathBuilders::DarkPathBuilder.new(metadata)
                when 'Flat'
                  PathBuilders::FlatPathBuilder.new(metadata)
                when 'Light'
                  PathBuilders::LightPathBuilder.new(metadata)
                when 'Bias'
                  PathBuilders::BiasPathBuilder.new(metadata)
                else
                  raise ArgumentError, "Unsupported type: #{metadata.type}"
                end
      builder.build
    end

    # Builds the full target path (folder + filename) for an image.
    #
    # @param metadata [Object] Image metadata object with filename and type
    # @return [String] The full path where the file will be moved
    def self.target_path_for(metadata)
      File.join(build_for(metadata), metadata.filename)
    end
  end
end
