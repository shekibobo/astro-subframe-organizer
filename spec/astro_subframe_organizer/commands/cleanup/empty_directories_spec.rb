# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer cleanup empty-directories', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  def create_dir(*path_parts)
    path = File.join(test_path, *path_parts)
    FileUtils.mkdir_p(path)
    path
  end

  def create_file(*path_parts)
    path = File.join(test_path, *path_parts)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
    path
  end

  context 'with empty directories' do
    let!(:empty_dir) { create_dir('empty') }

    before do
      run_command_and_stop "astro-subframe-organizer cleanup empty-directories --path #{test_path} --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'removes empty directories' do
      expect(File).not_to exist(empty_dir)
    end
  end

  context 'with a directory containing only .DS_Store' do
    let!(:ds_store) { create_file('ds_store_only', '.DS_Store') }

    before do
      run_command_and_stop "astro-subframe-organizer cleanup empty-directories --path #{test_path} --skip-confirm"
    end

    it 'removes the directory and .DS_Store' do
      expect(File).not_to exist(File.dirname(ds_store))
    end
  end

  context 'with populated directories' do
    let!(:fit_file) { create_file('subdir', 'image.fit') }

    before do
      run_command_and_stop "astro-subframe-organizer cleanup empty-directories --path #{test_path} --skip-confirm"
    end

    it 'does not remove populated directories' do
      expect(File).to exist(File.dirname(fit_file))
    end
  end

  context 'with --dry-run' do
    let!(:empty_dir) { create_dir('empty') }

    before do
      run_command_and_stop "astro-subframe-organizer cleanup empty-directories --path #{test_path} --dry-run --skip-confirm"
    end

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not remove empty directories' do
      expect(File).to exist(empty_dir)
    end
  end
end
