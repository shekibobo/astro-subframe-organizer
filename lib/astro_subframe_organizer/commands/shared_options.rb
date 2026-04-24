# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module SharedOptions
      def self.included(base)
        base.option :config, desc: 'Use custom config file'
        base.option :verbose, type: :boolean, default: false, desc: 'Enable verbose output'
        base.option :path, type: :string, default: Dir.pwd, required: false, desc: 'The path containing files to be organized'
        base.option :dry_run, type: :boolean, default: false, required: false, desc: 'Perform a dry-run showing the changes that would be made'
      end

      def setup(config: nil, verbose: false)
        ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG'] = config
        AstroSubframeOrganizer.logger.level = Logger::DEBUG if verbose
      end
    end
  end
end
