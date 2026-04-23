# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/utils/exif_renamer'

RSpec.describe AstroSubframeOrganizer::Utils::ExifRenamer do
  subject(:renamer) { described_class.new(test_dir) }

  let(:test_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(test_dir) }

  def copy_fixture(fixture_name)
    src  = File.expand_path("../../fixtures/cr2/#{fixture_name}", __dir__)
    dest = File.join(test_dir, fixture_name)
    FileUtils.cp(src, dest)
    dest
  end

  # Fixtures expected in spec/fixtures/cr2/:
  #
  # IMG_0001.CR2 - A standard Canon CR2 with SequenceNumber == 0 in EXIF.
  #                ExposureTime should be >= 1.0s (e.g. a dark or light frame).
  #                CameraTemperature should be present (e.g. -10.0).
  #                DateTimeOriginal should be present.
  #                Model should match a known camera in Equipment::Camera.all.
  #
  # IMG_0002.CR2 - A CR2 with ExposureTime < 1.0s (e.g. a flat or bias frame)
  #                to exercise millisecond exposure formatting.
  #
  # IMG_0003.CR2 - A CR2 with ExposureTime < 0.001s to exercise microsecond
  #                exposure formatting.
  #
  # IMG_0004.CR2 - A CR2 with a Model that does not match any known camera in
  #                Equipment::Camera.all, to exercise the fallback behavior.
  #
  # DARK_0001.CR2 - A CR2 whose filename does not start with IMG_, simulating
  #                 a file that has already been renamed, to exercise
  #                 already_named? detection.

  describe '#find_cr2_files' do
    context 'with CR2 files present' do
      before { copy_fixture('IMG_0001.CR2') }

      it 'finds CR2 files in the directory' do
        expect(renamer.find_cr2_files).not_to be_empty
      end

      it 'returns absolute paths' do
        expect(renamer.find_cr2_files).to all(start_with('/'))
      end
    end

    context 'with no CR2 files present' do
      it 'returns an empty array' do
        expect(renamer.find_cr2_files).to be_empty
      end
    end
  end

  describe '#already_named?' do
    # Expects: DARK_0001.CR2 — a file that does not start with IMG_
    context 'with already-renamed files' do
      it 'returns true' do
        files = [File.join(test_dir, 'DARK_0001.CR2')]
        expect(renamer.already_named?(files)).to be true
      end
    end

    # Expects: IMG_0001.CR2 — a standard unprocessed Canon CR2
    context 'with unprocessed IMG_ files' do
      it 'returns false' do
        files = [File.join(test_dir, 'IMG_0001.CR2')]
        expect(renamer.already_named?(files)).to be false
      end
    end

    context 'with an empty file list' do
      it 'returns true' do
        expect(renamer.already_named?([])).to be true
      end
    end
  end

  describe '#rename' do
    context 'with no CR2 files' do
      it 'does not raise an error' do
        expect { renamer.rename(type: Astrophoto::DARK) }.not_to raise_error
      end
    end

    # Expects: IMG_0001.CR2 — ExposureTime >= 1.0s, known camera model,
    #          CameraTemperature present, DateTimeOriginal present
    context 'with a standard dark frame' do
      before { copy_fixture('IMG_0001.CR2') }

      it 'renames the file with the correct type prefix' do
        renamer.rename(type: Astrophoto::DARK)
        renamed = Dir.glob('*.CR2', base: test_dir)
        expect(renamed.first).to start_with('Dark_')
      end

      it 'removes the original IMG_ file' do
        renamer.rename(type: Astrophoto::DARK)
        expect(File).not_to exist(File.join(test_dir, 'IMG_0001.CR2'))
      end

      it 'includes Bin1 in the filename' do
        renamer.rename(type: Astrophoto::DARK)
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to include('Bin1')
      end

      it 'includes the ISO in the filename' do
        renamer.rename(type: Astrophoto::DARK)
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to match(/ISO\d+/)
      end

      it 'includes the temperature in the filename' do
        renamer.rename(type: Astrophoto::DARK)
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to match(/-?\d+\.\d+C/)
      end
    end

    # Expects: IMG_0001.CR2 — a light frame needs a target name
    context 'with a light frame and target' do
      before { copy_fixture('IMG_0001.CR2') }

      it 'includes the target name in the filename' do
        renamer.rename(type: Astrophoto::LIGHT, target: 'M31')
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to include('M31')
      end
    end

    # Expects: IMG_0002.CR2 — ExposureTime < 1.0s, e.g. 1/500
    context 'with a short exposure (milliseconds)' do
      before { copy_fixture('IMG_0002.CR2') }

      it 'formats the exposure time in milliseconds' do
        renamer.rename(type: Astrophoto::FLAT)
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to match(/\d+\.\d+ms/)
      end
    end

    # Expects: IMG_0003.CR2 — ExposureTime < 0.001s
    context 'with a very short exposure (microseconds)' do
      before { copy_fixture('IMG_0003.CR2') }

      it 'formats the exposure time in microseconds' do
        renamer.rename(type: Astrophoto::FLAT)
        renamed = Dir.glob('*.CR2', base: test_dir).first
        expect(renamed).to match(/\d+\.\d+us/)
      end
    end

    # Expects: IMG_0001.CR2 — any valid CR2
    context 'with dry_run: true' do
      before { copy_fixture('IMG_0001.CR2') }

      it 'does not rename the file' do
        renamer.rename(type: Astrophoto::DARK, dry_run: true)
        expect(File).to exist(File.join(test_dir, 'IMG_0001.CR2'))
      end
    end

    # Expects: IMG_0001.CR2 — any valid CR2; run rename twice
    context 'when target file already exists' do
      before do
        copy_fixture('IMG_0001.CR2')
        renamer.rename(type: Astrophoto::DARK)
        copy_fixture('IMG_0001.CR2')
      end

      it 'does not raise an error' do
        expect { renamer.rename(type: Astrophoto::DARK) }.not_to raise_error
      end
    end
  end
end
