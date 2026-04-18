# frozen_string_literal: true

module AstroSubframeOrganizer
  class EquipmentSelector
    def initialize(cli = HighLine.new)
      @cli = cli
    end

    def choose_telescope
      choose('What telescope is this set for?', ::Telescope::ALL)
    end

    def choose_filter
      choose('What filter is used with this set?', ::Filter::ALL)
    end

    def choose_camera
      choose('What camera is used with this set?', ::Camera::ALL)
    end

    private

    def choose(prompt, options)
      @cli.choose do |menu|
        menu.prompt = prompt
        options.each { |option| menu.choice(option) }
        menu.default = options.first
      end
    end
  end
end
