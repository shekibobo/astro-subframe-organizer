# frozen_string_literal: true

require 'dry/cli'

require 'astro_subframe_organizer/commands/shared_options'
require 'astro_subframe_organizer/commands/equipment_options'
require 'astro_subframe_organizer/commands/init'
require 'astro_subframe_organizer/commands/run'
require 'astro_subframe_organizer/commands/version'
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
  module Commands
    extend Dry::CLI::Registry

    register 'version',    Commands::Version, aliases: ['v', '-v', '--version']
    register 'init',       Commands::Init
    register 'run',        Commands::Run

    register 'lights',     Commands::Organize::Lights, aliases: %w[light]
    register 'darks',      Commands::Organize::Darks, aliases: %w[dark]
    register 'flats',      Commands::Organize::Flats, aliases: %w[flat]
    register 'biases',     Commands::Organize::Bias, aliases: %w[bias]
    register 'unorganize', Commands::Cleanup::Unorganize, aliases: %w[reset revert]

    register 'cleanup', aliases: %w[clean] do |prefix|
      prefix.register 'thumbnails',
                      Commands::Cleanup::Thumbnails,
                      aliases: %w[thn thm th]

      prefix.register 'empty-directories',
                      Commands::Cleanup::EmptyDirectories,
                      aliases: %w[empty empties empty-folders]
    end

    register 'raw' do |prefix|
      prefix.register 'rename', Commands::Raw::RenameFromExif
      prefix.register 'revert', Commands::Raw::RevertToRaw
    end
  end
end
