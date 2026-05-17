# frozen_string_literal: true

require 'spec_helper'
require 'exiftool_vendored'
require 'astro_subframe_organizer/utils/raw_stripper'

describe AstroSubframeOrganizer::Utils::RawStripper, :files do
  let(:input_path) { File.join(test_dir, 'IMG_0001.CR2') }
  let(:output_path) { File.join(test_dir, 'test_stripped.CR2') }

  subject(:stripper) { described_class.new(input_path, output_path) }

  before do
    install_fixture('cr2/unstripped/IMG_0001.CR2', test_dir, dest_path: 'IMG_0001.CR2')
  end

  describe '#already_stripped?' do
    it 'returns false if output file does not exist' do
      expect(stripper.already_stripped?).to be false
    end

    it 'returns true if output file is small' do
      FileUtils.touch(output_path)
      expect(stripper.already_stripped?).to be true
    end

    it 'returns false if output file is large' do
      # Create a file larger than 1MB to simulate an unstripped RAW
      File.open(output_path, 'wb') { |f| f.write('0' * (1024 * 1024 + 1)) }
      expect(stripper.already_stripped?).to be false
    end
  end

  describe '#strip' do
    it 'successfully creates a smaller MIE-based file if exiftool is present' do
      Exiftool.command = 'exiftool.exe' if Gem.win_platform?
      executable = Exiftool.command

      has_exiftool = system("#{executable} -ver > /dev/null 2>&1")

      if has_exiftool
        original_size = File.size(input_path)
        expect(stripper.strip).to be true
        expect(File.exist?(output_path)).to be true
        expect(File.size(output_path)).to be < original_size
        # MIE files are significantly smaller (usually < 100KB)
        expect(File.size(output_path)).to be < 200_000
      else
        # Gracefully handle missing dependency
        # stripper.strip returns false if system call fails
        expect(stripper.strip).to be false
        expect(File.exist?(output_path)).to be false
      end
    end
  end
end
