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
      ]
    }.freeze

    def self.config_file
      ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG'] || File.expand_path('~/.astro_subframe_organizer.yml')
    end

    def self.load
      if File.exist?(config_file)
        DEFAULT_CONFIG.merge(YAML.load_file(config_file))
      else
        DEFAULT_CONFIG
      end
    rescue StandardError
      DEFAULT_CONFIG
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

    def self.create_default_config
      File.write(config_file, DEFAULT_CONFIG.to_yaml)
    end
  end
end
