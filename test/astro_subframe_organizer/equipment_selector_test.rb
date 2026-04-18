# frozen_string_literal: true

require_relative '../test_helper'

class TestEquipmentSelector < AstroSubframeOrganizer::Test
  class DummyMenu
    attr_accessor :prompt, :default

    def initialize
      @choices = []
    end

    def choice(option)
      @choices << option
    end
  end

  class FakeCLI
    attr_reader :menu

    def choose
      @menu = DummyMenu.new
      yield @menu
      @menu.default
    end
  end

  def test_choose_telescope_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_telescope

    assert_equal Telescope::ALL.first, selected
    assert_equal 'What telescope is this set for?', cli.menu.prompt
  end

  def test_choose_filter_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_filter

    assert_equal Filter::ALL.first, selected
    assert_equal 'What filter is used with this set?', cli.menu.prompt
  end

  def test_choose_camera_uses_configured_options
    cli = FakeCLI.new
    selector = EquipmentSelector.new(cli)

    selected = selector.choose_camera

    assert_equal Camera::ALL.first, selected
    assert_equal 'What camera is used with this set?', cli.menu.prompt
  end
end
