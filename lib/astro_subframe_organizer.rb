# frozen_string_literal: true

require "astro_subframe_organizer/version"
require 'astro_subframe_organizer/utils/file_utils'
require "astro_subframe_organizer/logging"
require "astro_subframe_organizer/utils/exposure_format"

require "astro_subframe_organizer/commands"

require "astro_subframe_organizer/config"
require "astro_subframe_organizer/equipment/camera"
require "astro_subframe_organizer/equipment/filter"
require "astro_subframe_organizer/equipment/telescope"

require "astro_subframe_organizer/filename_parser"
require "astro_subframe_organizer/filename_parsers/cr2_filename_parser"
require "astro_subframe_organizer/filename_parsers/fits_filename_parser"
require "astro_subframe_organizer/filename_parsers/fits_header_parser"

require "astro_subframe_organizer/path_builders/base_path_builder"
require "astro_subframe_organizer/path_builders/bias_path_builder"
require "astro_subframe_organizer/path_builders/dark_path_builder"
require "astro_subframe_organizer/path_builders/flat_path_builder"
require "astro_subframe_organizer/path_builders/light_path_builder"
require "astro_subframe_organizer/path_builder"

require "astro_subframe_organizer/astrophoto"
require 'astro_subframe_organizer/file_metadata'
require "astro_subframe_organizer/file_set"

require "astro_subframe_organizer/equipment_selector"
require "astro_subframe_organizer/organizer"
require "astro_subframe_organizer/fits_organizer"

require 'astro_subframe_organizer/utils/thumbnail_cleaner'
require 'astro_subframe_organizer/utils/empty_directory_cleaner'
require 'astro_subframe_organizer/utils/unorganizer'

require 'logger'
require 'fileutils'
require 'date'
require 'tty-progressbar'
require 'tty-prompt'
require 'yaml'

FILENAME_DT_FORMAT = '%Y%m%d-%H%M%S'

module AstroSubframeOrganizer
  class << self
    attr_writer :logger

    def logger
      @logger ||= default_logger
    end

    def prompt
      @prompt ||= default_prompt
    end

    def default_logger
      logger = Logger.new($stdout)
      logger.level = Logger::INFO
      logger.formatter = proc do |severity, _datetime, _progname, msg|
        case severity
        when "ERROR", "FATAL" then "✗ #{msg}\n"
        when "WARN"           then "⚠ #{msg}\n"
        when "DEBUG"          then "[debug] #{msg}\n"
        else                       "#{msg}\n" # INFO → plain output
        end
      end
      logger
    end

    private

    def default_prompt
      TTY::Prompt.new(
        active_color: :bright_cyan,
        help_color: :bright_white,
        error_color: :bright_red,
      )
    end
  end

  def self.run(dry_run: nil)
    logger.info "Using config file at #{Config.config_file}" if Config.config_file
    organizer = FitsOrganizer.new(dry_run: dry_run)
    organizer.organize
  end
end
