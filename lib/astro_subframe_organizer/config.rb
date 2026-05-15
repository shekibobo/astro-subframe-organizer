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
      'cameras' => %w[
        T7
        183MC
      ],
    }.freeze

    def self.custom_config_file
      ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG']
    end

    # Returns the expanded path to the configuration file.
    def self.config_file
      path = custom_config_file || '~/.astro-subframe-organizer.yml'
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

    def self.create_default_config
      File.write(config_file, DEFAULT_CONFIG.to_yaml)
    end
  end
end
