# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    class Bias < Dry::CLI::Command
      include SharedOptions

      desc 'Run the subframe organizer for bias calibration frames'

      def call(config: nil, verbose: false, dry_run: false, path: Dir.pwd, **)
        setup(config: config, verbose: verbose)
        Organizer.new(type: Astrophoto::BIAS, path: path).organize(dry_run: dry_run)
      end
    end
  end
end
