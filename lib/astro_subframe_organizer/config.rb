# frozen_string_literal: true

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
      # Ensure output is flushed immediately, which is critical for
      # reliable output capture in CI environments like Windows.
      $stdout.sync = true

      @load ||=
        if File.exist?(config_file)
          AstroSubframeOrganizer.logger.info "Using config file at #{config_file}"
          DEFAULT_CONFIG.merge(YAML.load_file(config_file))
        elsif custom_config_file
          AstroSubframeOrganizer.logger.error("Unable to find #{config_file}. Check path and try again.")
          exit(1)
        else
          AstroSubframeOrganizer.logger.info "Using config file at #{config_file}"
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
