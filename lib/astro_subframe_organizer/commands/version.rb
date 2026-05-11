# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Version < Dry::CLI::Command
      desc 'Print version'

      def call(*)
        puts AstroSubframeOrganizer::VERSION
      end
    end
  end
end
