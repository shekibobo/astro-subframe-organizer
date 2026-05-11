# frozen_string_literal: true

require 'spec_helper'

describe 'astro-subframe-organizer cleanup thumbnails', type: :aruba do
  let(:test_path) { aruba.config.home_directory }

  def create_file(*path_parts)
    path = File.join(test_path, *path_parts)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
    path
  end

  context 'with thumbnail files present' do
    let!(:thumbnail)     { create_file('image_thn.jpg') }
    let!(:sub_thumbnail) { create_file('subdir', 'other_thn.jpg') }
    let!(:regular_jpg)   { create_file('image.jpg') }
    let!(:fit_file)      { create_file('image.fit') }

    before { run_command_and_stop "astro-subframe-organizer cleanup thumbnails --path #{test_path}" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'removes thumbnail files' do
      expect(File).not_to exist(thumbnail)
      expect(File).not_to exist(sub_thumbnail)
    end

    it 'does not remove non-thumbnail files' do
      expect(File).to exist(regular_jpg)
      expect(File).to exist(fit_file)
    end
  end

  context 'with a custom pattern' do
    let!(:custom_thumbnail) { create_file('image_thumb.png') }
    let!(:thumbnail)        { create_file('image_thn.jpg') }

    before do
      run_command_and_stop(
        "astro-subframe-organizer cleanup thumbnails --path #{test_path} --pattern '**/*_thumb.png'",
      )
    end

    it 'removes files matching the custom pattern' do
      expect(File).not_to exist(custom_thumbnail)
    end

    it 'does not remove files not matching the custom pattern' do
      expect(File).to exist(thumbnail)
    end
  end

  context 'with --dry-run' do
    let!(:thumbnail) { create_file('image_thn.jpg') }

    before { run_command_and_stop "astro-subframe-organizer cleanup thumbnails --path #{test_path} --dry-run" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not remove any files' do
      expect(File).to exist(thumbnail)
    end
  end

  context 'with no matching files' do
    let!(:regular_jpg) { create_file('image.jpg') }

    before { run_command_and_stop "astro-subframe-organizer cleanup thumbnails --path #{test_path}" }

    it 'exits successfully' do
      expect(last_command_started.exit_status).to eq(0)
    end

    it 'does not remove any files' do
      expect(File).to exist(regular_jpg)
    end
  end

  context 'with nested subdirectories' do
    let!(:deep_thumbnail) { create_file('a', 'b', 'c', 'image_thn.jpg') }

    before { run_command_and_stop "astro-subframe-organizer cleanup thumbnails --path #{test_path}" }

    it 'removes thumbnails in deeply nested directories' do
      expect(File).not_to exist(deep_thumbnail)
    end
  end
end
