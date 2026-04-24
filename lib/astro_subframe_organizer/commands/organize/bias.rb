# lib/astro_subframe_organizer/commands/organize/lights.rb
# frozen_string_literal: true

module AstroSubframeOrganizer
  module Commands
    module Organize
      class Bias < Base
        desc 'Run the subframe organizer for bias subframes'
        def frame_type = Astrophoto::BIAS
      end
    end
  end
end
