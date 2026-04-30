# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module SharedOptions
      def self.included(base)
        base.option :config, desc: 'Use custom config file'
        base.option :verbose, type: :boolean, default: false, desc: 'Enable verbose output'
        base.option :path, type: :string, default: Dir.pwd, required: false, desc: 'The path containing files to be organized'
        base.option :dry_run, type: :boolean, default: false, required: false, desc: 'Perform a dry-run showing the changes that would be made'
        base.option :skip_confirm, type: :boolean, required: false, default: false, desc: 'Skip confirmation prompts'
      end

      def setup(config: nil, verbose: false, skip_confirm: false)
        ENV['ASTRO_SUBFRAME_ORGANIZER_CONFIG'] = config
        ENV['ASTRO_SUBFRAME_SKIP_CONFIRM'] = 'true' if skip_confirm
        AstroSubframeOrganizer.logger.level = Logger::DEBUG if verbose
      end
    end
  end
end
