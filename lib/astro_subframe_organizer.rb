# frozen_string_literal: true

require_relative "astro_subframe_organizer/version"
require_relative "astro_subframe_organizer/astrophoto"
require_relative "astro_subframe_organizer/equipment/telescope"
require_relative "astro_subframe_organizer/equipment/filter"
require_relative "astro_subframe_organizer/equipment/camera"
require_relative "astro_subframe_organizer/path_builders/base_path_builder"
require_relative "astro_subframe_organizer/path_builders/dark_path_builder"
require_relative "astro_subframe_organizer/path_builders/flat_path_builder"
require_relative "astro_subframe_organizer/path_builders/light_path_builder"
require_relative "astro_subframe_organizer/path_builders/bias_path_builder"
require_relative "astro_subframe_organizer/path_builder"
require_relative "astro_subframe_organizer/fits_organizer"
require_relative "astro_subframe_organizer/filename_parser"
require_relative "astro_subframe_organizer/filename_parsers/cr2_parser"
require_relative "astro_subframe_organizer/filename_parsers/fits_parser"

require 'fileutils'
require 'date'
require 'highline'
require 'mini_exiftool'

module AstroSubframeOrganizer
  def self.run
    organizer = FitsOrganizer.new
    organizer.organize
  end
end
