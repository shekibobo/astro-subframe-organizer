# frozen_string_literal: true

require 'dry/cli'

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Flats < Base
        desc 'Run the subframe organizer for flat subframes'
        def frame_type = Astrophoto::FLAT
      end
    end
  end
end
