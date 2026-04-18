# frozen_string_literal: true

require_relative '../test_helper'

class TestFileSet < Minitest::Test
  class MockFile
    attr_accessor :type, :path, :image_index, :camera, :telescope, :filter, :dark_flat, :target_path, :current_dir, :already_moved

    def initialize(type, path, image_index, camera = nil, telescope = nil, filter = nil, dark_flat = false, target_path = nil, current_dir = nil, already_moved = false)
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
      MockFile.new('Dark', 'a_0001.fit', '1', 'T7', nil, nil, false, 'a_0001', '/fake', false),
      MockFile.new('Dark', 'a_0002.fit', '1', 'T7', nil, nil, false, 'a_0002', '/fake', false),
      MockFile.new('Dark', 'b_0003.fit', '2', 'T7', nil, nil, false, 'b_0003', '/fake', false)
    ]

    sets = AstroSubframeOrganizer::FileSet.from_files(files, type: 'Dark')

    assert_equal 2, sets.size
    assert_equal 2, sets.first.files.size
    assert_equal 1, sets.last.files.size
  end

  def test_camera_candidates_and_resolution
    files = [
      MockFile.new('Light', 'a_0001.fit', '1', 'T7', nil, nil, false, 'a_0001', '/fake', false),
      MockFile.new('Light', 'a_0002.fit', '1', nil, nil, nil, false, 'a_0002', '/fake', false)
    ]
    set = AstroSubframeOrganizer::FileSet.new(files)

    assert_equal ['T7'], set.camera_candidates
    assert_equal 'T7', set.camera
  end

  def test_apply_camera_sets_missing_camera_values
    files = [
      MockFile.new('Light', 'a_0001.fit', '1', 'T7', nil, nil, false, 'a_0001', '/fake', false),
      MockFile.new('Light', 'a_0002.fit', '1', nil, nil, nil, false, 'a_0002', '/fake', false)
    ]
    set = AstroSubframeOrganizer::FileSet.new(files)

    set.apply_camera!('T7')

    assert_equal 'T7', files.last.camera
  end

  def test_mark_dark_flat_updates_all_files
    files = [
      MockFile.new('Dark', 'a_0001.fit', '1', 'T7', nil, nil, false, 'a_0001', '/fake', false),
      MockFile.new('Dark', 'a_0002.fit', '1', 'T7', nil, nil, false, 'a_0002', '/fake', false)
    ]
    set = AstroSubframeOrganizer::FileSet.new(files)

    set.mark_dark_flat!

    assert_equal true, files.all?(&:dark_flat)
  end
end
