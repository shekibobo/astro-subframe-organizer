# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module EquipmentOptions
      def self.included(base)
        base.option :telescope, type: :string, required: false, desc: 'Name of telescope used to create subframes'
        base.option :camera, type: :string, required: false, desc: 'Name of camera used to create subframes'
        base.option :filter, type: :string, required: false, desc: 'Name of filter used to create subframes'
      end

      attr_reader :equipment_selector

      # Set the equipment on an equipment selector during organizing. If a value is not provided
      # via command line option, the organizer will follow default rules for determing equipment
      # selection:
      #   - If available in filename or FITS headers, and it matches equipment in Config, auto-selected.
      #   - If not determined, will prompt the user to select an option from Config equipment.
      #
      # Only use this if the command uses equipment selector. Otherwise, use +options+ directly.
      def set_equipment(telescope: nil, camera: nil, filter: nil)
        @equipment_selector = EquipmentSelector.new.tap do |eq|
          eq.telescope = telescope
          eq.camera = camera
          eq.filter = filter
        end
      end
    end
  end
end
