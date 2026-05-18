# frozen_string_literal: true

require 'fileutils'
require 'exiftool_vendored'

module AstroSubframeOrganizer
  module Utils
    # Strips RAW files down to their metadata by creating a MIE (Metadata Information Extraction) file using exiftool.
    # This is useful for users who want to keep metadata but remove large image data from their RAW files, for example
    # to generate test fixtures where metadata is important, but image data is not needed.
    class RawStripper
      def initialize(input_path, output_path)
        @input = input_path
        @output = output_path
      end

      def already_stripped?
        # A stripped RAW (MIE file) is typically under 1MB,
        # whereas a real RAW is 20MB+.
        return false unless File.exist?(@output)

        File.size(@output) < 1_048_576
      end

      def strip # rubocop:disable Naming/PredicateMethod
        # We use exiftool to create a Metadata Information Extraction (MIE) file.
        # This contains all metadata but zero image data.
        # We then save it with the original extension so the parsers recognize it.
        tmp_mie = "#{@output}.mie"
        Exiftool.command = 'exiftool.exe' if Gem.win_platform?

        # -o specifies the output file. exiftool creates a MIE file if the extension is .mie
        # -all:all ensures we copy all metadata blocks (EXIF, MakerNotes, etc.)
        success = system("#{Exiftool.command} -o \"#{tmp_mie}\" -all:all \"#{@input}\" > /dev/null 2>&1")

        if success && File.exist?(tmp_mie)
          FileUtils.mkdir_p(File.dirname(@output))
          FileUtils.mv(tmp_mie, @output, force: true)
          true
        else
          FileUtils.rm_f(tmp_mie)
          false
        end
      end
    end
  end
end
