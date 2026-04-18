# frozen_string_literal: true

module AstroSubframeOrganizer
  module PathBuilders
    # Base class for all path builders.
    #
    # Path builders construct folder paths based on image metadata, using keywords that
    # facilitate organization for PixInsight's WeightedBatchPreProcessing (WBPP) script.
    # WBPP uses these keywords to automatically match and group images for calibration and
    # integration tasks.
    #
    # Subclasses should implement a `build` method that returns the folder path as a string
    # with keyword-value pairs separated by underscores (e.g., "Dark_ISO_100_EXP_30.0s_...").
    #
    # See README.md for details on how WBPP uses these keywords in the calibration workflow.
    class BasePathBuilder
      def initialize(metadata)
        @metadata = metadata
      end

      protected

      # @return [String, nil] "ISO_<value>" if iso is present, "GAIN_<value>" if gain is present
      def iso_or_gain
        if @metadata.iso
          "ISO_#{@metadata.iso}"
        elsif @metadata.gain
          "GAIN_#{@metadata.gain}"
        end
      end

      # @return [String] The flatset ID (date-based grouping for flats and flat darks)
      def flatset_id
        @metadata.flatset_id
      end

      # @return [String] Year-Month in YYYY-MM format (used for seasonal dark grouping)
      def month
        @metadata.month
      end
    end
  end
end
