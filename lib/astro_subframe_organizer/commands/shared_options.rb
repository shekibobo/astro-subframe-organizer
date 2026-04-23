# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module SharedOptions
      def self.included(base)
        base.option :config, desc: 'Use custom config file'
        base.option :verbose, type: :boolean, default: false, desc: 'Enable verbose output'
      end

      def setup(config: nil, verbose: false)
        ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG'] = config if config
        AstroSubframeOrganizer.logger.level = Logger::DEBUG if verbose
      end
    end
  end
end
