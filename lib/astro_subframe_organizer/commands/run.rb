# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Run < Dry::CLI::Command
      include SharedOptions

      desc 'Run the subframe organizer'

      def call(**options)
        setup(**options.slice(:config, :verbose, :skip_confirm))
        AstroSubframeOrganizer.run
      end
    end
  end
end
