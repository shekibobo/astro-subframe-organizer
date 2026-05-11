# lib/astro_subframe_organizer/commands/organize/base.rb
# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Base < Dry::CLI::Command
        include SharedOptions
        include EquipmentOptions

        def self.inherited(subclass)
          super
          subclass.example [
            '# Default - interactive menu using default configuration file in the current directory',
            '--path /Volumes/Sirius/staging/ # organize files under specified directory',
            '--config ~/galaxy-season-config.yml # interactive menu using specified configuration',
            '--telescope RedCat51 --camera 183MC --filter BaaderMoon --skip-confirm # organize using the specified equipment, no confirmation prompts',
            "--telescope 'William Optics RedCat51' --camera 'ZWO ASI183MC Pro' --filter 'Baader Moon & Skyglow' --skip-confirm # equipment with spaces or special characters require quotes",
          ]
        end

        def call(dry_run: false, path: Dir.pwd, **options)
          setup(**options.slice(:config, :verbose, :skip_confirm))
          set_equipment(**options.slice(:telescope, :camera, :filter))

          Organizer.new(
            type: frame_type,
            path: path,
            equipment_selector: equipment_selector,
          ).organize(dry_run: dry_run)
        end

        private

        def frame_type
          raise NotImplementedError, "#{self.class} must implement frame_type"
        end
      end
    end
  end
end
