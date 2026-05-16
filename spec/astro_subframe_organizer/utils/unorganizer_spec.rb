# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/utils/unorganizer'

module AstroSubframeOrganizer
  module Utils
    describe Unorganizer, :files do
      subject(:unorganizer) { described_class.new(test_dir) }

      def create_organized_file(*path_parts)
        path = File.join(test_dir, *path_parts)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
        path
      end

      describe '#unorganize' do
        context 'with no organized files' do
          it 'does not raise' do
            expect { unorganizer.unorganize }.not_to raise_error
          end
        end

        context 'with organized FITS files in subdirectories' do
          let!(:organized_fit) do
            create_organized_file(
              'Light_M42_FLATSET_20220508_GAIN_111_EXP_300.0s_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_183MC',
              'Light_M42_300.0s_Bin1_183MC_gain111_20220508-120000_-10.0C_0001.fit',
            )
          end

          it 'moves the file to the root directory' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'Light_M42_300.0s_Bin1_183MC_gain111_20220508-120000_-10.0C_0001.fit'))
          end

          it 'removes the file from the subdirectory' do
            unorganizer.unorganize
            expect(File).not_to exist(organized_fit)
          end

          it 'removes the empty subdirectory' do
            unorganizer.unorganize
            subdirs = Dir.glob(File.join(test_dir, '*/'))
            expect(subdirs).to be_empty
          end
        end

        context 'with organized CR2 files in subdirectories' do
          let!(:organized_cr2) do
            create_organized_file(
              'Light_M42_FLATSET_20220508_ISO_100_EXP_1.0s_Bin_1_TELESCOPE_RedCat51_FILTER_NoFilter_CAMERA_T7',
              'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.CR2',
            )
          end

          it 'moves the CR2 file to the root directory' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'Light_M42_1.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.CR2'))
          end

          it 'removes the file from the subdirectory' do
            unorganizer.unorganize
            expect(File).not_to exist(organized_cr2)
          end
        end

        context 'with files already in the root directory' do
          let!(:root_file) do
            path = File.join(test_dir, 'Light_M42_300.0s_0001.fit')
            FileUtils.touch(path)
            path
          end

          it 'does not move root-level files' do
            unorganizer.unorganize
            expect(File).to exist(root_file)
          end
        end

        context 'when a file with the same name already exists in root' do
          let(:filename) { 'Light_M42_300.0s_0001.fit' }

          before do
            FileUtils.touch(File.join(test_dir, filename))
            create_organized_file('SomeOrganizedDir', filename)
          end

          it 'skips the duplicate without raising' do
            expect { unorganizer.unorganize }.not_to raise_error
          end

          it 'leaves the original root file intact' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, filename))
          end
        end

        context 'with files in deeply nested subdirectories' do
          let!(:deep_file) do
            create_organized_file('subdir', 'deeper', 'Light_M42_300.0s_0001.fit')
          end

          it 'moves files from nested directories' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'Light_M42_300.0s_0001.fit'))
          end
        end

        context 'with dry_run: true' do
          let!(:organized_fit) do
            create_organized_file('SomeOrganizedDir', 'Light_M42_300.0s_0001.fit')
          end

          it 'does not move any files' do
            unorganizer.unorganize(dry_run: true)
            expect(File).to exist(organized_fit)
            expect(File).not_to exist(File.join(test_dir, 'Light_M42_300.0s_0001.fit'))
          end

          it 'does not remove subdirectories' do
            unorganizer.unorganize(dry_run: true)
            expect(File).to exist(File.join(test_dir, 'SomeOrganizedDir'))
          end
        end

        context 'with mixed file types in subdirectories' do
          before do
            create_organized_file('SomeOrganizedDir', 'Light_M42_300.0s_0001.fit')
            create_organized_file('SomeOrganizedDir', 'Light_M42_300.0s_0002.CR2')
            create_organized_file('SomeOrganizedDir', 'thumbnail.jpg')
          end

          it 'moves only FITS and CR2 files' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'Light_M42_300.0s_0001.fit'))
            expect(File).to exist(File.join(test_dir, 'Light_M42_300.0s_0002.CR2'))
          end

          it 'leaves non-raw files in place' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'SomeOrganizedDir', 'thumbnail.jpg'))
          end

          it 'does not remove the subdirectory since it still has files' do
            unorganizer.unorganize
            expect(File).to exist(File.join(test_dir, 'SomeOrganizedDir'))
          end
        end
      end
    end
  end
end
