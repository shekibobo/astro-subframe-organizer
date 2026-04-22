# frozen_string_literal: true

require 'dry/cli'

require 'astro_subframe_organizer/commands/init'
require 'astro_subframe_organizer/commands/run'

module AstroSubframeOrganizer
  module Commands
    extend Dry::CLI::Registry

    register 'init', Commands::Init
    register 'run',  Commands::Run
  end
end
