# frozen_string_literal: true

module AstroSubframeOrganizer
  # Value object representing parsed metadata from an astrophotography file
  class FileMetadata
    attr_accessor :path, :type, :target, :camera, :telescope, :filter, :dark_flat
    attr_reader :filename,
                :file_format,
                :exposure,
                :bin,
                :gain,
                :iso,
                :created_at,
                :ccd_temp,
                :image_index,
                :mosaic_pane

    def initialize(
      type:, path:, filename:, file_format:, exposure: nil, bin: nil, camera: nil,
      iso: nil, gain: nil, created_at: nil, ccd_temp: nil, image_index: nil,
      target: nil, telescope: nil, filter: nil, dark_flat: false, mosaic_pane: nil
    )
      @type = type
      @path = path
      @filename = filename
      @file_format = file_format
      @exposure = exposure
      @bin = bin
      @camera = camera
      @iso = iso
      @gain = gain
      @created_at = created_at
      @ccd_temp = ccd_temp
      @image_index = image_index
      @target = target
      @telescope = telescope
      @filter = filter
      @dark_flat = dark_flat
      @mosaic_pane = mosaic_pane
    end

    # Factory method to create FileMetadata from parsed parser result
    def self.from_parsed_data(parsed_data)
      return parsed_data if parsed_data.instance_of? FileMetadata

      new(
        type: parsed_data[:type],
        path: parsed_data[:path],
        filename: parsed_data[:filename],
        file_format: parsed_data[:file_format],
        target: parsed_data[:target],
        mosaic_pane: parsed_data[:mosaic_pane],
        exposure: parsed_data[:exposure],
        bin: parsed_data[:bin],
        camera: parsed_data[:camera],
        iso: parsed_data[:iso],
        gain: parsed_data[:gain],
        created_at: parsed_data[:created_at],
        ccd_temp: parsed_data[:ccd_temp],
        image_index: parsed_data[:image_index],
        telescope: parsed_data[:telescope],
        filter: parsed_data[:filter],
        dark_flat: parsed_data[:dark_flat] || false,
      )
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

    def rounded_ccd_temp(tolerance: Config.temperature_tolerance)
      return nil if ccd_temp.nil?

      temp_value = ccd_temp.to_f
      rounded    = (temp_value / tolerance).round * tolerance
      format('%.1fC', rounded)
    end
  end
end
