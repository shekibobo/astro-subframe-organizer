# frozen_string_literal: true

module AstroSubframeOrganizer
  class EquipmentSelector
    include Equipment
    include Logging

    attr_accessor :telescope, :camera, :filter

    def initialize(
      prompt = AstroSubframeOrganizer.prompt,
      telescopes: Telescope.all,
      cameras: Camera.all,
      filters: Filter.all
    )
      @telescopes = telescopes
      @cameras = cameras
      @filters = filters
      @prompt = prompt
    end

    def choose_telescope(index = nil)
      generic_choose(telescope, @telescopes, 'telescope', index, 'What telescope is this set for?')
    end

    def choose_telescope_or_confirm(detected:)
      if detected && Config.telescope_ignore_patterns.any? { |p| detected.match?(p) }
        logger.info "Ignoring detected mount name: '#{detected}'"
        detected = nil
      end

      if detected
        suggestion = "If '#{detected}' is a mount name, consider adding it to 'telescope_ignore_patterns' in your config."
      end
      generic_choose_or_confirm(telescope, @telescopes, 'telescope', 'TELESCOP', detected, suggestion: suggestion)
    end

    def choose_camera(index = nil)
      generic_choose(camera, @cameras, 'camera', index)
    end

    def choose_camera_or_confirm(detected:)
      generic_choose_or_confirm(camera, @cameras, 'camera', 'INSTRUME', detected)
    end

    def choose_filter(index = nil)
      generic_choose(filter, @filters, 'filter', index)
    end

    def choose_filter_or_confirm(detected:)
      generic_choose_or_confirm(filter, @filters, 'filter', 'FILTER', detected)
    end

    private

    def generic_choose(current_value, collection, label, index = nil, custom_prompt = nil)
      return current_value if current_value

      if index && collection[index]
        collection[index]
      elsif collection.one?
        collection.first
      else
        prompt_text = custom_prompt || "What #{label} is used with this set?"
        choose(prompt_text, collection)
      end.tap { |it| logger.info("Selected #{label.capitalize}: #{it}") }
    end

    def generic_choose_or_confirm(current_value, collection, label, header_name, detected, suggestion: nil)
      if current_value
        logger.warn "Using #{label} #{current_value}, but detected #{detected}" if detected && current_value != detected
        return current_value
      end

      if detected && collection.include?(detected)
        detected
      elsif detected
        logger.warn "#{header_name} header '#{detected}' is not in the configured #{label} list."
        logger.info suggestion if suggestion
        choose(
          "#{header_name} is '#{detected}' — select the actual #{label} or confirm:",
          [detected] + collection,
        ).tap { |it| logger.info("Selected #{label.capitalize}: #{it}") }
      else
        logger.warn "#{label.capitalize} auto-detect failed."
        send("choose_#{label}")
      end
    end

    def choose(prompt, options)
      @prompt.enum_select prompt, options
    end
  end
end
