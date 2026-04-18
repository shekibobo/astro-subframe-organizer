# frozen_string_literal: true

require_relative "astro_subframe_organizer/version"
require_relative "astro_subframe_organizer/telescope"
require_relative "astro_subframe_organizer/filter"
require_relative "astro_subframe_organizer/camera"
require_relative "astro_subframe_organizer/astrophoto"
require_relative "astro_subframe_organizer/fits_organizer"
require_relative "astro_subframe_organizer/path_builders/base_path_builder"
require_relative "astro_subframe_organizer/path_builders/dark_path_builder"
require_relative "astro_subframe_organizer/path_builders/flat_path_builder"
require_relative "astro_subframe_organizer/path_builders/light_path_builder"
require_relative "astro_subframe_organizer/path_builders/bias_path_builder"
require_relative "astro_subframe_organizer/path_builder"

# Copyright 2022 Joshua Kovach
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

require 'fileutils'
require 'date'
require 'highline'
require 'mini_exiftool'

module AstroSubframeOrganizer
  def self.run
    organizer = FitsOrganizer.new
    organizer.organize
  end
end
