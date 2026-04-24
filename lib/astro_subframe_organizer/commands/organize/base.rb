# lib/astro_subframe_organizer/commands/organize/base.rb
# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Base < Dry::CLI::Command
        include SharedOptions
        include EquipmentOptions

        def call(dry_run: false, path: Dir.pwd, **options)
          setup(**options.slice(:config, :verbose))
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
