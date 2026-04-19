# frozen_string_literal: true

module AstroSubframeOrganizer
  class EquipmentSelector
    include Equipment
    def initialize(cli = CLI::UI::Prompt)
      @cli = cli
    end

    def choose_telescope
      choose('What telescope is this set for?', Telescope::ALL)
    end

    def choose_filter
      choose('What filter is used with this set?', Filter::ALL)
    end

    def choose_camera
      choose('What camera is used with this set?', Camera::ALL)
    end

    private

    def choose(prompt, options)
      @cli.ask prompt, options: options
    end
  end
end
