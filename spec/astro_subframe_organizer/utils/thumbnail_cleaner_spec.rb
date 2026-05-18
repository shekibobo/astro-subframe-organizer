# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/utils/thumbnail_cleaner'

module AstroSubframeOrganizer
  module Utils
    describe ThumbnailCleaner, :files do
      subject(:cleaner) { described_class.new(test_dir) }

      def create_file(*path_parts)
        path = File.join(test_dir, *path_parts)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
        path
      end

      describe '#cleanup' do
        context 'with thumbnail files present' do
          let!(:thumbnail)     { create_file('image_thn.jpg') }
          let!(:sub_thumbnail) { create_file('subdir', 'other_thn.jpg') }
          let!(:regular_jpg)   { create_file('image.jpg') }
          let!(:fit_file)      { create_file('image.fit') }

          it 'removes thumbnail files matching the default pattern' do
            cleaner.cleanup
            expect(File).not_to exist(thumbnail)
            expect(File).not_to exist(sub_thumbnail)
          end

          it 'does not remove non-thumbnail jpg files' do
            cleaner.cleanup
            expect(File).to exist(regular_jpg)
          end

          it 'does not remove non-jpg files' do
            cleaner.cleanup
            expect(File).to exist(fit_file)
          end
        end

        context 'with a custom pattern' do
          let!(:custom_thumbnail) { create_file('image_thumb.png') }
          let!(:regular_file)     { create_file('image_thn.jpg') }

          it 'removes files matching the custom pattern' do
            cleaner.cleanup(pattern: '**/*_thumb.png')
            expect(File).not_to exist(custom_thumbnail)
          end

          it 'does not remove files not matching the custom pattern' do
            cleaner.cleanup(pattern: '**/*_thumb.png')
            expect(File).to exist(regular_file)
          end
        end

        context 'with dry_run: true' do
          let!(:thumbnail) { create_file('image_thn.jpg') }

          it 'does not remove any files' do
            cleaner.cleanup(dry_run: true)
            expect(File).to exist(thumbnail)
          end
        end

        context 'with no matching files' do
          let!(:regular_jpg) { create_file('image.jpg') }

          it 'does not raise an error' do
            expect { cleaner.cleanup }.not_to raise_error
          end

          it 'does not remove any files' do
            cleaner.cleanup
            expect(File).to exist(regular_jpg)
          end
        end

        context 'with nested subdirectories' do
          let!(:deep_thumbnail) { create_file('a', 'b', 'c', 'image_thn.jpg') }

          it 'removes thumbnails in deeply nested directories' do
            cleaner.cleanup
            expect(File).not_to exist(deep_thumbnail)
          end
        end
      end
    end
  end
end
