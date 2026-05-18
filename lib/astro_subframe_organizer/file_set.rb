# frozen_string_literal: true

module AstroSubframeOrganizer
  # Value object representing a set of files that belong together based on type and metadata.
  class FileSet
    include Enumerable

    attr_reader :files

    def initialize(files)
      @files = files
    end

    # Factory method to create list of FileSet instances from a list of FileMetadata objects,
    # grouping them by type and relevant metadata.
    def self.from_files(files, type:)
      files.select { |file| file.type == type }
           # Normalize path for sorting: unified separators and consistent case (for Windows)
           .sort_by { |file| [File.dirname(file.path).tr('\\', '/').downcase, file.filename.downcase] }
           .slice_when { |a, b| new_group?(a, b) }
           .map { |group| new(group) }
    end

    def self.new_group?(first, second)
      first.image_index.to_i > second.image_index.to_i ||
        first.camera != second.camera ||
        first.telescope != second.telescope ||
        first.filter != second.filter
    end

    def name
      "#{type} set #{files.first.filename}..#{files.last.filename}"
    end

    def each(&)
      @files.each(&)
    end

    def size
      @files.size
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
      files.filter_map(&:camera).uniq
    end

    def camera
      camera_candidates.one? ? camera_candidates.first : nil
    end

    def apply_camera!(camera)
      files.each { |file| file.camera = camera }
    end

    def telescope_candidates
      files.filter_map(&:telescope).uniq
    end

    def telescope
      telescope_candidates.one? ? telescope_candidates.first : nil
    end

    def apply_telescope!(telescope)
      files.each { |file| file.telescope = telescope }
    end

    def filter_candidates
      files.filter_map(&:filter).uniq
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
