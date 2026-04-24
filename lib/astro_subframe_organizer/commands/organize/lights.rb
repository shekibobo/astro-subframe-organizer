# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Lights < Base
        desc 'Run the subframe organizer for light subframes'
        def frame_type = Astrophoto::LIGHT
      end
    end
  end
end
