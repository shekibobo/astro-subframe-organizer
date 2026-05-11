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
