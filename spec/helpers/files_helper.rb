# frozen_string_literal: true

require 'tempfile'
require 'fileutils'
require 'tmpdir'

# Fixtures in spec/fixtures/fits/ are header-only FITS files stripped with
# bin/strip_fits. One representative file from each set is used per frame type.
#
# light-blanks: Light frames, target "C 1", 300s, Bin1, 183MC, gain 111,
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

module FilesHelper
  def test_dir
    @test_dir
  end

  def fixture(relative_path)
    File.join(FIXTURE_ROOT, relative_path)
  end

  def install_fixture(source, dest_dir, dest_path: nil)
    src = fixture(source)
    target = File.join(dest_dir, dest_path || source)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(src, target)
    target
  end

  def skip_unless_fixture_exists(path)
    skip "Fixture not found: #{path}" unless File.exist?(path)
  end
end

RSpec.configure  do |config|
  config.include FilesHelper, files: true
  config.include FilesHelper, type: :aruba

  config.around(:each, files: true) do |example|
    Dir.mktmpdir do |dir|
      @test_dir = dir
      example.run
    end
  end
end
