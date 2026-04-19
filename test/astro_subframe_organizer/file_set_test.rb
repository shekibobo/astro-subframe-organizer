# frozen_string_literal: true

require_relative '../test_helper'

class TestFileSet < AstroSubframeOrganizer::Test
  class MockFile
    attr_accessor :type, :path, :image_index, :camera, :telescope, :filter, :dark_flat, :target_path, :current_dir, :already_moved

    def initialize(
      type:,
      path:,
      image_index:,
      camera: nil,
      telescope: nil,
      filter: nil,
      dark_flat: false,
      target_path: nil,
      current_dir: nil,
      already_moved: false
    )
      @type = type
      @path = path
      @image_index = image_index
      @camera = camera
      @telescope = telescope
      @filter = filter
      @dark_flat = dark_flat
      @target_path = target_path
      @current_dir = current_dir
      @already_moved = already_moved
    end

    def move(_); end
    def already_moved? = @already_moved
    def maybe_flat_dark? = !dark_flat && type == 'Dark'
  end

  def test_groups_files_by_image_index
    files = [
      MockFile.new(
        type: 'Dark',
        path: 'a_0001.fit',
        image_index: '1',
        camera: 'T7',
        target_path: 'a_0001',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Dark',
        path: 'a_0002.fit',
        image_index: '2',
        camera: 'T7',
        target_path: 'a_0002',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Dark',
        path: 'a_0002.fit',
        image_index: '3',
        camera: 'T7',
        target_path: 'a_0003',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Dark',
        path: 'b_0001.fit',
        image_index: '1',
        camera: 'T7',
        target_path: 'b_0003',
        current_dir: '/fake',
      ),
    ]

    sets = FileSet.from_files(files, type: 'Dark')

    assert_equal 2, sets.size
    assert_equal 3, sets.first.files.size
    assert_equal 1, sets.last.files.size
  end

  def test_camera_candidates_and_resolution
    files = [
      MockFile.new(
        type: 'Light',
        path: 'a_0001.fit',
        image_index: '1',
        camera: 'T7',
        telescope: nil,
        filter: nil,
        dark_flat: false,
        target_path: 'a_0001',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Light',
        path: 'a_0002.fit',
        image_index: '1',
        camera: nil,
        telescope: nil,
        filter: nil,
        dark_flat: false,
        target_path: 'a_0002',
        current_dir: '/fake',
      ),
    ]
    set = FileSet.new(files)

    assert_equal ['T7'], set.camera_candidates
    assert_equal 'T7', set.camera
  end

  def test_apply_camera_sets_missing_camera_values
    files = [
      MockFile.new(
        type: 'Light',
        path: 'a_0001.fit',
        image_index: '1',
        camera: 'T7',
        telescope: nil,
        filter: nil,
        dark_flat: false,
        target_path: 'a_0001',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Light',
        path: 'a_0002.fit',
        image_index: '1',
        camera: nil,
        telescope: nil,
        filter: nil,
        dark_flat: false,
        target_path: 'a_0002',
        current_dir: '/fake',
      ),
    ]
    set = FileSet.new(files)

    set.apply_camera!('T7')

    assert_equal 'T7', files.last.camera
  end

  def test_mark_dark_flat_updates_all_files
    files = [
      MockFile.new(
        type: 'Dark',
        path: 'a_0001.fit',
        image_index: '1',
        camera: 'T7',
        target_path: 'a_0001',
        current_dir: '/fake',
      ),
      MockFile.new(
        type: 'Dark',
        path: 'a_0002.fit',
        image_index: '1',
        camera: 'T7',
        target_path: 'a_0002',
        current_dir: '/fake',
      ),
    ]
    set = FileSet.new(files)

    set.mark_dark_flat!

    assert_equal true, files.all?(&:dark_flat)
  end
end
