# frozen_string_literal: true

require 'dry/cli'

require 'astro_subframe_organizer/commands/shared_options'
require 'astro_subframe_organizer/commands/init'
require 'astro_subframe_organizer/commands/run'
require 'astro_subframe_organizer/commands/lights'
require 'astro_subframe_organizer/commands/darks'
require 'astro_subframe_organizer/commands/flats'
require 'astro_subframe_organizer/commands/bias'
require 'astro_subframe_organizer/commands/cleanup_thumbnails'

module AstroSubframeOrganizer
  module Commands
    extend Dry::CLI::Registry

    register 'init',   Commands::Init
    register 'run',    Commands::Run
    register 'lights', Commands::Lights, aliases: %w[light]
    register 'darks',  Commands::Darks, aliases: %w[dark]
    register 'flats',  Commands::Flats, aliases: %w[flat]
    register 'biases', Commands::Bias, aliases: %w[bias]

    register 'cleanup', aliases: %w[clean] do |prefix|
      prefix.register 'thumbnails', Commands::CleanupThumbnails, aliases: %w[thn thm th]
    end
  end
end
