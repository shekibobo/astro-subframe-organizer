# frozen_string_literal: true

require 'yaml'

# Ensure standard streams are unbuffered for reliable output capture in CI (especially Windows)
$stdout.sync = true
$stderr.sync = true

module AstroSubframeOrganizer
  # Configuration management for user-customizable options
  class Config
    DEFAULT_CONFIG = {
      'telescopes' => %w[
        RedCat51
        ZhumellZ130
        AperturaAD8
        MeadeDS90
        CanonEFS1855
      ],
      'filters' => %w[
        BaaderMoon
        NBZ
        NoFilter
      ],
      'cameras' => [
        'T7',
        '183MC',
        'ZWO ASI183MC Pro',
        'Canon EOS 1500D',
      ],
      'temperature_tolerance' => 5.0,
      'fits_extensions' => %w[.fit .fits .fts],
      'raw_extensions' => %w[.cr2 .cr3 .nef .arw .orf .raf .dng],
      'exif_tag_mappings' => {
        'temperature' => %i[camera_temperature sensor_temperature ambient_temperature],
        'iso' => %i[iso base_iso],
        'exposure' => %i[exposure_time],
        'model' => %i[model],
        'timestamp' => %i[date_time_original],
      },
      'fits_header_mappings' => {
        'temperature' => %w[CCD-TEMP SET-TEMP TEMP],
        'gain' => %w[GAIN GAINVAL],
        'exposure' => %w[EXPOSURE EXPTIME],
        'filter' => %w[FILTER FILTERNAME],
        'telescope' => %w[TELESCOP],
        'target' => %w[OBJECT TARGET],
        'camera' => %w[INSTRUME],
        'binning' => %w[XBINNING CCDXBIN BINNING],
        'type' => %w[IMAGETYP FRAME],
        'date_obs' => %w[DATE-OBS DATE],
        'rotation' => %w[ROTATANG ANGLE POSANGLE ROTATOR ROTAT OBJCTROT CCDROTSA],
        'iso' => %w[ISO],
      },
      'telescope_ignore_patterns' => [
        'Mount',
        'EQMod',
        'AM5',
        'AM3',
        'RST-135',
        'Star Adventurer',
      ],
    }.freeze

    def self.custom_config_file
      ENV.fetch('ASTRO_SUBFRAME_ORGANIZER_CONFIG', nil)
    end

    # Returns the expanded path to the configuration file.
    def self.config_file
      path = custom_config_file || '~/astro-subframe-organizer-config.yml'
      File.expand_path(path)
    end

    def self.load
      @load ||=
        if File.exist?(config_file)
          # Normalize path separators for consistent logging/testing across platforms
          AstroSubframeOrganizer.logger.info "Using config file at #{config_file.tr('\\', '/')}"
          DEFAULT_CONFIG.merge(YAML.safe_load_file(config_file, permitted_classes: [Symbol, DateTime]))
        elsif custom_config_file
          AstroSubframeOrganizer.logger.error("Unable to find #{config_file.tr('\\', '/')}. Check path and try again.")
          exit(1)
        else
          AstroSubframeOrganizer.logger.info "Using config file at #{config_file.tr('\\', '/')}"
          DEFAULT_CONFIG
        end
    rescue StandardError => e
      AstroSubframeOrganizer.logger.error("Failed to parse #{config_file}: #{e}")
    end

    def self.all_telescopes
      load['telescopes']
    end

    def self.all_filters
      load['filters']
    end

    def self.all_cameras
      load['cameras']
    end

    def self.temperature_tolerance
      load['temperature_tolerance']&.to_f || 5.0
    end

    def self.fits_extensions
      load['fits_extensions'] || DEFAULT_CONFIG['fits_extensions']
    end

    def self.raw_extensions
      load['raw_extensions'] || DEFAULT_CONFIG['raw_extensions']
    end

    def self.exif_tag_mappings
      load['exif_tag_mappings'] || DEFAULT_CONFIG['exif_tag_mappings']
    end

    def self.fits_header_mappings
      load['fits_header_mappings'] || DEFAULT_CONFIG['fits_header_mappings']
    end

    def self.telescope_ignore_patterns
      patterns = load['telescope_ignore_patterns'] || DEFAULT_CONFIG['telescope_ignore_patterns']
      patterns.map { |p| Regexp.new(Regexp.escape(p), Regexp::IGNORECASE) }
    end

    def self.create_default_config
      # Only include basic equipment and settings in the generated template.
      # Advanced mappings and ignore patterns are handled via application defaults
      # unless explicitly overridden by the user.
      template = DEFAULT_CONFIG.slice(
        'telescopes', 'filters', 'cameras', 'temperature_tolerance'
      )

      File.write(config_file, template.to_yaml)
    end
  end
end
