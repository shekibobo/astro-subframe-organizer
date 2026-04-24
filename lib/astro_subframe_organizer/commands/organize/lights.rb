# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Lights < Dry::CLI::Command
        include SharedOptions
        include EquipmentOptions

        desc 'Run the subframe organizer for light subframes'

        def call(dry_run: false, path: Dir.pwd, **options)
          setup(**options.slice(:config, :verbose))
          set_equipment(**options.slice(:telescope, :camera, :filter))

          Organizer.new(
            type: Astrophoto::LIGHT,
            path: path,
            equipment_selector: equipment_selector,
          ).organize(dry_run: dry_run)
        end
      end
    end
  end
end
