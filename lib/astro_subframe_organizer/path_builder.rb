# frozen_string_literal: true

module AstroSubframeOrganizer
  class PathBuilder
    def initialize(metadata)
      @metadata = metadata
    end

    def target_dir
      case @metadata.type
      when 'Dark'
        dark_directory
      when 'Flat'
        flat_directory
      when 'Light'
        light_directory
      when 'Bias'
        bias_directory
      else
        raise ArgumentError, "Unsupported type: #{@metadata.type}"
      end
    end

    def target_path
      File.join(target_dir, @metadata.filename)
    end

    private

    def iso_or_gain
      if @metadata.iso
        "ISO_#{@metadata.iso}"
      elsif @metadata.gain
        "GAIN_#{@metadata.gain}"
      end
    end

    def flatset_id
      @metadata.flatset_id
    end

    def month
      @metadata.month
    end

    def dark_directory
      return dark_flat_directory if @metadata.dark_flat?

      [
        'Dark',
        iso_or_gain,
        "EXP_#{@metadata.exposure}",
        "CCD-TEMP_#{@metadata.ccd_temp}",
        "CAMERA_#{@metadata.camera}",
        "MONTH_#{month}"
      ].compact.join('_')
    end

    def dark_flat_directory
      [
        'DarkFlat',
        "FLATSET_#{flatset_id}",
        iso_or_gain,
        "EXP_#{@metadata.exposure}",
        "Bin_#{@metadata.bin}",
        "CAMERA_#{@metadata.camera}"
      ].compact.join('_')
    end

    def flat_directory
      [
        'Flat',
        "FLATSET_#{flatset_id}",
        iso_or_gain,
        "EXP_#{@metadata.exposure}",
        "Bin_#{@metadata.bin}",
        "TELESCOPE_#{@metadata.telescope}",
        "FILTER_#{@metadata.filter}",
        "CAMERA_#{@metadata.camera}"
      ].compact.join('_')
    end

    def light_directory
      pane_segment = @metadata.mosaic_pane ? "_PANE_#{@metadata.mosaic_pane}" : ''
      prefix = "Light_#{@metadata.target}#{pane_segment}"

      case @metadata.file_format
      when :fits
        [
          prefix,
          "FLATSET_#{flatset_id}",
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "TELESCOPE_#{@metadata.telescope}",
          "FILTER_#{@metadata.filter}",
          "CAMERA_#{@metadata.camera}"
        ].compact.join('_')
      when :cr2
        [
          prefix,
          "FLATSET_#{flatset_id}",
          iso_or_gain,
          "EXP_#{@metadata.exposure}",
          "Bin_#{@metadata.bin}",
          "CCD-TEMP_#{@metadata.ccd_temp.gsub('0C', '')}",
          "TELESCOPE_#{@metadata.telescope}",
          "FILTER_#{@metadata.filter}",
          "CAMERA_#{@metadata.camera}"
        ].compact.join('_')
      else
        raise ArgumentError, "Unsupported format: #{@metadata.file_format}"
      end
    end

    def bias_directory
      [
        'Bias',
        iso_or_gain,
        "EXP_#{@metadata.exposure}",
        "Bin_#{@metadata.bin}",
        "CAMERA_#{@metadata.camera}",
        "MONTH_#{month}"
      ].compact.join('_')
    end
  end
end
