# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'minitest/pride'
require 'tempfile'
require 'fileutils'
require_relative '../lib/astro_subframe_organizer'

class Minitest::Test
  include AstroSubframeOrganizer

  # Helper method to create a temporary FITS file with the given name and content
  def create_temp_fits_file(name, content = '')
    file = Tempfile.new([name, '.fit'])
    file.write(content)
    file.rewind
    file
  end

  # Helper method to capture stdout output during tests
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
