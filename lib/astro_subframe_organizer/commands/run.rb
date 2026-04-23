# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Run < Dry::CLI::Command
      include SharedOptions

      desc 'Run the subframe organizer'

      def call(config: nil, verbose: false, **)
        setup(config: config, verbose: verbose)
        AstroSubframeOrganizer.run
      end
    end
  end
end
