# frozen_string_literal: true

require 'dry/cli'

require 'astro_subframe_organizer/commands/shared_options'
require 'astro_subframe_organizer/commands/equipment_options'
require 'astro_subframe_organizer/commands/init'
require 'astro_subframe_organizer/commands/run'
require 'astro_subframe_organizer/commands/version'
require 'astro_subframe_organizer/commands/inspect'
require 'astro_subframe_organizer/commands/organize/base'
require 'astro_subframe_organizer/commands/organize/lights'
require 'astro_subframe_organizer/commands/organize/darks'
require 'astro_subframe_organizer/commands/organize/flats'
require 'astro_subframe_organizer/commands/organize/bias'
require 'astro_subframe_organizer/commands/raw/rename_from_exif'
require 'astro_subframe_organizer/commands/raw/revert_name'
require 'astro_subframe_organizer/commands/cleanup/thumbnails'
require 'astro_subframe_organizer/commands/cleanup/empty_directories'
require 'astro_subframe_organizer/commands/cleanup/unorganize'

module AstroSubframeOrganizer
  # The main command registry for the AstroSubframeOrganizer CLI, using Dry::CLI to define and
  # organize commands and their aliases. This module registers all the available commands for
  # the CLI, including:
  #
  # - Version display
  # - Initialization of configuration
  # - Running the organizer in interactive mode
  # - Inspecting file metadata
  # - Organizing different types of subframes (lights, darks, flats, biases)
  # - Renaming RAW files based on EXIF data
  # - Cleaning up thumbnails and empty directories
  # - Reverting organization changes
  module Commands
    extend Dry::CLI::Registry

    register 'version',    Version, aliases: ['v', '-v', '--version']
    register 'init',       Init, aliases: ['--init']
    register 'run',        Run, aliases: %w[-i --interactive]
    register 'inspect',    Inspect, aliases: %w[metadata view headers]

    register 'lights',     Organize::Lights, aliases: %w[light --light --lights]
    register 'darks',      Organize::Darks, aliases: %w[dark --dark --darks]
    register 'flats',      Organize::Flats, aliases: %w[flat --flat --flats]
    register 'biases',     Organize::Bias, aliases: %w[bias --bias --biases]
    register 'unorganize', Cleanup::Unorganize, aliases: %w[reset revert undo]

    register 'cleanup', aliases: %w[clean] do |prefix|
      prefix.register 'thumbnails',
                      Cleanup::Thumbnails,
                      aliases: %w[thn thm th thumbs]

      prefix.register 'empty-directories',
                      Cleanup::EmptyDirectories,
                      aliases: %w[empty empties empty-folders]
    end

    register 'raw' do |prefix|
      prefix.register 'rename', Raw::RenameFromExif, aliases: %w[autoname]
      prefix.register 'revert', Raw::RevertToRaw, aliases: %w[undo reset]
    end
  end
end
