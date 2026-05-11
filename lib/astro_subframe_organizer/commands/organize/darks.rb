# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Darks < Base
        desc 'Run the subframe organizer for dark subframes'
        def frame_type = Astrophoto::DARK
      end
    end
  end
end
