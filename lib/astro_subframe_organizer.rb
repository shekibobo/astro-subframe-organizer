# frozen_string_literal: true

# Ensure standard streams are unbuffered for reliable output capture in CI and Aruba tests
$stdout.sync = true
$stderr.sync = true

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
        # Disable colors and interactive features in RSpec to make output matching reliable
        enable_color: !ENV['RSPEC_RUNNING'].nil? ? false : true,
        interrupt: :exit,
      )
    end
  end

  def self.run(dry_run: nil, path: Dir.pwd, stdin: $stdin, stdout: $stdout, stderr: $stderr)
    # Redirect streams immediately to capture initialization logs
    original_stdin = $stdin
    original_stdout = $stdout
    original_stderr = $stderr
    $stdin  = stdin
    $stdout = stdout
    $stderr = stderr

    @logger = nil # Force logger to re-initialize with the redirected $stdout
    @prompt = nil # Clear cached prompt so it picks up the new $stdin/$stdout

    begin
      logger.info "Using config file at #{Config.config_file}" if Config.config_file

      # The prompt will now be initialized with the injected streams
      organizer = FitsOrganizer.new(path, dry_run: dry_run)
      organizer.organize
    ensure
      # Restore original streams
      $stdin = original_stdin
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end
end
