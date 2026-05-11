# frozen_string_literal: true

module AstroSubframeOrganizer
  class FileSet
    include Enumerable

    attr_reader :files

    def initialize(files)
      @files = files
    end

    def self.from_files(files, type:)
      files.select { |file| file.type == type }
           .sort_by(&:path)
           .slice_when { |a, b| a.image_index.to_i > b.image_index.to_i }
           .map { |group| new(group) }
    end

    def name
      "#{type} set #{files.first.filename}..#{files.last.filename}"
    end

    def each(&block)
      @files.each(&block)
    end

    def type
      files.first.type
    end

    def current_dir
      files.first.current_dir
    end

    def already_moved?
      files.all?(&:already_moved?)
    end

    def all_unmoved?
      files.all? { |file| file.path != file.target_path }
    end

    def any_unmoved?
      files.any? { |file| file.path != file.target_path }
    end

    def camera_candidates
      files.map(&:camera).compact.uniq
    end

    def camera
      camera_candidates.one? ? camera_candidates.first : nil
    end

    def apply_camera!(camera)
      files.each { |file| file.camera = camera }
    end

    def telescope_candidates
      files.map(&:telescope).compact.uniq
    end

    def telescope
      telescope_candidates.one? ? telescope_candidates.first : nil
    end

    def apply_telescope!(telescope)
      files.each { |file| file.telescope = telescope }
    end

    def filter_candidates
      files.map(&:filter).compact.uniq
    end

    def filter
      filter_candidates.one? ? filter_candidates.first : nil
    end

    def apply_filter!(filter)
      files.each { |file| file.filter = filter }
    end

    def maybe_flat_dark?
      files.all?(&:maybe_flat_dark?)
    end

    def mark_dark_flat!
      files.each { |file| file.dark_flat = true }
    end
  end
end
