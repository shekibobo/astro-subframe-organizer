# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe EquipmentSelector do
    let(:telescopes) { %w[RedCat51 ZhumellZ130] }
    let(:cli) { FakeCLI.new }

    subject(:selector) do
      described_class.new(cli, telescopes: telescopes)
    end

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

    describe '#choose_telescope_or_confirm' do
      context 'when telescope is already set on the selector' do
        before { selector.telescope = 'RedCat51' }

        it 'returns the preset telescope without prompting' do
          expect(cli).not_to receive(:ask)
          expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('RedCat51')
        end
      end

      context 'when detected telescope matches a configured telescope' do
        it 'returns the detected telescope without prompting' do
          expect(cli).not_to receive(:ask)
          expect(selector.choose_telescope_or_confirm(detected: 'RedCat51')).to eq('RedCat51')
        end
      end

      context 'when detected telescope is a mount name not in the configured list' do
        before do
          allow(cli).to receive(:ask).and_return('RedCat51')
        end

        it 'prompts with the mount name and configured telescopes' do
          selector.choose_telescope_or_confirm(detected: 'EQMod Mount')
          expect(cli).to have_received(:ask).with(
            a_string_including('EQMod Mount'),
            options: ['EQMod Mount', 'RedCat51', 'ZhumellZ130'],
          )
        end

        it 'returns the selected telescope' do
          expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('RedCat51')
        end

        it 'allows accepting the mount name as-is' do
          allow(cli).to receive(:ask).and_return('EQMod Mount')
          expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('EQMod Mount')
        end
      end

      context 'when no telescope is detected' do
        before do
          allow(cli).to receive(:ask).and_return('RedCat51')
        end

        it 'falls back to the standard telescope prompt' do
          selector.choose_telescope_or_confirm(detected: nil)
          expect(cli).to have_received(:ask).with(
            'What telescope is this set for?',
            options: telescopes,
          )
        end
      end

      context 'when only one telescope is configured' do
        let(:telescopes) { ['RedCat51'] }

        context 'when TELESCOP header is absent' do
          it 'returns the only configured telescope without prompting' do
            expect(cli).not_to receive(:ask)
            expect(selector.choose_telescope_or_confirm(detected: nil)).to eq('RedCat51')
          end
        end

        context 'when TELESCOP header matches the configured telescope' do
          it 'returns the configured telescope without prompting' do
            expect(cli).not_to receive(:ask)
            expect(selector.choose_telescope_or_confirm(detected: 'RedCat51')).to eq('RedCat51')
          end
        end

        context 'when TELESCOP header is a mount name not in the configured list' do
          before { allow(cli).to receive(:ask).and_return('RedCat51') }

          it 'prompts with the mount name and the single configured telescope' do
            selector.choose_telescope_or_confirm(detected: 'EQMod Mount')
            expect(cli).to have_received(:ask).with(
              a_string_including('EQMod Mount'),
              options: ['EQMod Mount', 'RedCat51'],
            )
          end

          it 'returns the selected telescope' do
            expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('RedCat51')
          end

          it 'allows accepting the mount name as-is' do
            allow(cli).to receive(:ask).and_return('EQMod Mount')
            expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('EQMod Mount')
          end
        end
      end
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
