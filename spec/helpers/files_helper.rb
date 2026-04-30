# frozen_string_literal: true

require 'tempfile'
require 'fileutils'

# Fixtures in spec/fixtures/fits/ are header-only FITS files stripped with
# bin/strip_fits. One representative file from each set is used per frame type.
#
# C1-blanks:    Light frames, target "C 1", 300s, Bin1, 183MC, gain 111,
#               rotation 288deg, -10.0C, captured 2026-04-10 through 2026-04-11
#
# dark-blanks:  Dark frames at multiple exposures (1s, 5s, 10s, 30s, 60s,
#               120s, 180s, 300s, 600s), Bin1, 183MC, gain 111, -10.0C
#               Note: some files have -10.5C or -9.5C temp variations
#
# flat-blanks:  Flat frames, rotation 293deg, 5s, Bin1, 183MC, gain 111,
#               captured across three sessions: 2025-12-24, 2026-01-13,
#               2026-02-18. Some files have -9.5C or -10.5C temp variations.

FIXTURE_ROOT = File.expand_path('../fixtures', __dir__)
puts FIXTURE_ROOT
puts Dir.exist?(FIXTURE_ROOT)

module FilesHelper
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

  def fixture(relative_path)
    File.join(FIXTURE_ROOT, relative_path)
  end

  def skip_unless_fixture_exists(path)
    skip "Fixture not found: #{path}" unless File.exist?(path)
  end
end

RSpec.configure  do |config|
  config.include FilesHelper, files: true
end
