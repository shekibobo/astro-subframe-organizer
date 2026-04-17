# frozen_string_literal: true

module AstroSubframeOrganizer
  # Value object representing parsed metadata from an astrophotography file
  # Immutable after creation to prevent accidental mutations
  class FileMetadata
    attr_reader :type, :target, :exposure, :bin, :camera, :gain, :iso, :created_at,
                :ccd_temp, :image_index, :path, :filename, :telescope, :filter,
                :dark_flat, :mosaic_pane, :file_format

    def initialize(attributes = {})
      @type = attributes[:type]
      @path = attributes[:path]
      @filename = attributes[:filename]
      @file_format = attributes[:file_format]
      @exposure = attributes[:exposure]
      @bin = attributes[:bin]
      @camera = attributes[:camera]
      @iso = attributes[:iso]
      @gain = attributes[:gain]
      @created_at = attributes[:created_at]
      @ccd_temp = attributes[:ccd_temp]
      @image_index = attributes[:image_index]
      @target = attributes[:target]
      @telescope = attributes[:telescope]
      @filter = attributes[:filter]
      @dark_flat = attributes[:dark_flat] || false
      @mosaic_pane = attributes[:mosaic_pane]

      freeze
    end

    # Factory method to create FileMetadata from parsed parser result
    def self.from_parsed_data(parsed_data)
      new(parsed_data)
    end

    def dark_flat?
      dark_flat
    end

    # True if the dark is likely a dark flat and hasn't already been organized as dark flat
    def maybe_flat_dark?
      exp_val = exposure.to_f
      exp_units = exposure.gsub(exp_val.to_s, '')
      exp_in_seconds = case exp_units
                       when 's'
                         exp_val
                       when 'ms'
                         exp_val / 1000.0
                       when 'us'
                         exp_val / 1_000_000.0
                       end
      type == 'Dark' && exp_in_seconds <= 10.0 && !dark_flat?
    end

    # The date formatted like '20220508'. If pictures taken in latter half of day,
    # assume flatset will be generated the next day
    def flatset_id
      if type == 'Light' && created_at.hour >= 12
        created_at.next_day.strftime('%Y%m%d')
      else
        created_at.strftime('%Y%m%d')
      end
    end

    # The Year-Month in which image was taken. Useful for grouping darks by season
    def month
      created_at.strftime('%Y-%m')
    end

    # Current directory of the file
    def current_dir
      segments = File.split(path) - [filename]
      File.join(*segments)
    end

    # True if the path is already at target destination
    def already_moved?(target_path)
      path == target_path
    end
  end
end
