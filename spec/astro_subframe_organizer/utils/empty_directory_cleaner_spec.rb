# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/utils/empty_directory_cleaner'

module AstroSubframeOrganizer
  module Utils
    describe EmptyDirectoryCleaner, :files do
      subject(:cleaner) { described_class.new(test_dir) }

      def create_dir(*path_parts)
        path = File.join(test_dir, *path_parts)
        FileUtils.mkdir_p(path)
        path
      end

      def create_file(*path_parts)
        path = File.join(test_dir, *path_parts)
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
        path
      end

      describe '#cleanup' do
        context 'with empty directories' do
          let!(:empty_dir) { create_dir('empty') }

          it 'removes the empty directory' do
            cleaner.cleanup
            expect(File).not_to exist(empty_dir)
          end
        end

        context 'with a directory containing only .DS_Store' do
          let!(:ds_store_dir) { create_dir('ds_store_only') }
          let!(:ds_store)     { create_file('ds_store_only', '.DS_Store') }

          it 'removes the directory' do
            cleaner.cleanup
            expect(File).not_to exist(ds_store_dir)
          end

          it 'removes the .DS_Store file' do
            cleaner.cleanup
            expect(File).not_to exist(ds_store)
          end
        end

        context 'with a directory containing files' do
          let!(:populated_dir) { create_dir('populated') }
          let!(:fit_file)      { create_file('populated', 'image.fit') }

          it 'does not remove the directory' do
            cleaner.cleanup
            expect(File).to exist(populated_dir)
          end
        end

        context 'with nested empty directories' do
          let!(:parent) { create_dir('parent') }
          let!(:child)  { create_dir('parent', 'child') }

          it 'removes the child directory' do
            cleaner.cleanup
            expect(File).not_to exist(child)
          end

          it 'removes the parent directory' do
            cleaner.cleanup
            expect(File).not_to exist(parent)
          end
        end

        context 'with nested directories where parent has files' do
          let!(:parent)   { create_dir('parent') }
          let!(:child)    { create_dir('parent', 'child') }
          let!(:fit_file) { create_file('parent', 'image.fit') }

          it 'removes the empty child directory' do
            cleaner.cleanup
            expect(File).not_to exist(child)
          end

          it 'does not remove the parent directory' do
            cleaner.cleanup
            expect(File).to exist(parent)
          end
        end

        context 'with dry_run: true' do
          let!(:empty_dir) { create_dir('empty') }
          let!(:ds_store)  { create_file('ds_store_only', '.DS_Store') }

          it 'does not remove empty directories' do
            cleaner.cleanup(dry_run: true)
            expect(File).to exist(empty_dir)
          end

          it 'does not remove .DS_Store files' do
            cleaner.cleanup(dry_run: true)
            expect(File).to exist(ds_store)
          end
        end

        context 'with no empty directories' do
          let!(:fit_file) { create_file('subdir', 'image.fit') }

          it 'does not raise an error' do
            expect { cleaner.cleanup }.not_to raise_error
          end

          it 'does not remove any files' do
            cleaner.cleanup
            expect(File).to exist(fit_file)
          end
        end
      end
    end
  end
end
