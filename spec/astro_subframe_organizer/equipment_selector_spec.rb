# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe EquipmentSelector do
    let(:cli) { FakeCLI.new }
    let(:selector) { EquipmentSelector.new(cli: cli) }

    it 'chooses telescope using configured options' do
      selected = selector.choose_telescope

      expect(selected).to eq(Equipment::Telescope.all.first)
      expect(cli.menu.prompt).to eq('What telescope is this set for?')
    end

    it 'chooses filter using configured options' do
      selected = selector.choose_filter

      expect(selected).to eq(Equipment::Filter.all.first)
      expect(cli.menu.prompt).to eq('What filter is used with this set?')
    end

    it 'chooses camera using configured options' do
      selected = selector.choose_camera

      expect(selected).to eq(Equipment::Camera.all.first)
      expect(cli.menu.prompt).to eq('What camera is used with this set?')
    end
  end
end

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
