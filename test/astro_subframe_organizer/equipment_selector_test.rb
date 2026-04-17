# frozen_string_literal: true

require_relative '../test_helper'

class TestEquipmentSelector < AstroSubframeOrganizer::Test
  class DummyMenu
    attr_accessor :prompt, :choices

    def option(option)
      @choices ||= []
      @choices << option
    end
  end

  class FakeCLI
    attr_reader :menu

    def ask(prompt, options:)
      @menu = DummyMenu.new
      @menu.prompt = prompt
      options.each { |option| @menu.option(option) }
      options.first
    end
  end

  def test_choose_telescope_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_telescope

    assert_equal Telescope.all.first, selected
    assert_equal 'What telescope is this set for?', cli.menu.prompt
  end

  def test_choose_filter_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_filter

    assert_equal Filter.all.first, selected
    assert_equal 'What filter is used with this set?', cli.menu.prompt
  end

  def test_choose_camera_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_camera

    assert_equal Camera.all.first, selected
    assert_equal 'What camera is used with this set?', cli.menu.prompt
  end
end
