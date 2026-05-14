# frozen_string_literal: true

require 'fileutils'

module FileUtils
  # We redefine the internal output method used by FileUtils
  def self.fu_output_message(msg)
    AstroSubframeOrganizer.logger.info(msg)
  end
end
