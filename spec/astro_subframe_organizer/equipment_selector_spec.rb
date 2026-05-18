# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  describe EquipmentSelector do
    let(:telescopes) { %w[RedCat51 ZhumellZ130] }
    let(:cameras) { %w[T7 183MC] }
    let(:filters) { %w[BaaderMoon NBZ] }
    let(:prompt) { instance_double(TTY::Prompt) }

    subject(:selector) do
      described_class.new(prompt, telescopes: telescopes, cameras: cameras, filters: filters)
    end

    before do
      allow(prompt).to receive(:enum_select).and_return(telescopes.first)
      allow(AstroSubframeOrganizer.logger).to receive(:info)
      allow(AstroSubframeOrganizer.logger).to receive(:warn)
    end

    it 'chooses telescope using configured options' do
      selected = selector.choose_telescope
      expect(selected).to eq(Equipment::Telescope.all.first)
      expect(prompt).to have_received(:enum_select).with('What telescope is this set for?', anything)
    end

    it 'chooses filter using configured options' do
      allow(prompt).to receive(:enum_select).and_return(Equipment::Filter.all.first)
      selected = selector.choose_filter
      expect(selected).to eq(Equipment::Filter.all.first)
      expect(prompt).to have_received(:enum_select).with('What filter is used with this set?', anything)
    end

    it 'chooses camera using configured options' do
      allow(prompt).to receive(:enum_select).and_return(Equipment::Camera.all.first)
      selected = selector.choose_camera
      expect(selected).to eq(Equipment::Camera.all.first)
      expect(prompt).to have_received(:enum_select).with('What camera is used with this set?', anything)
    end

    describe '#choose_telescope_or_confirm' do
      context 'when telescope is already set on the selector' do
        before { selector.telescope = 'RedCat51' }

        it 'returns the preset telescope without prompting' do
          expect(prompt).not_to receive(:enum_select)
          expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('RedCat51')
        end
      end

      context 'when detected telescope matches a configured telescope' do
        it 'returns the detected telescope without prompting' do
          expect(prompt).not_to receive(:enum_select)
          expect(selector.choose_telescope_or_confirm(detected: 'RedCat51')).to eq('RedCat51')
        end
      end

      context 'when detected telescope matches an ignore pattern (e.g. ASIAir Mount name)' do
        before do
          allow(prompt).to receive(:enum_select).and_return('RedCat51')
        end

        it 'ignores the mount name and prompts for a known telescope' do
          selector.choose_telescope_or_confirm(detected: 'EQMod Mount')
          expect(prompt).to have_received(:enum_select).with(
            'What telescope is this set for?',
            telescopes,
          )
        end

        it 'logs that the mount name was ignored and that auto-detect failed' do
          selector.choose_telescope_or_confirm(detected: 'EQMod Mount')
          expect(AstroSubframeOrganizer.logger).to have_received(:info).with(/Ignoring detected mount name: 'EQMod Mount'/)
          expect(AstroSubframeOrganizer.logger).to have_received(:warn).with(/Telescope auto-detect failed/)
        end
      end

      context 'when detected telescope is unknown (not ignored, but not in config)' do
        before do
          allow(prompt).to receive(:enum_select).and_return('RedCat51')
        end

        it 'logs a mismatch warning and a suggestion, then prompts to confirm the detected value or select' do
          selector.choose_telescope_or_confirm(detected: 'Strange Scope')

          expect(AstroSubframeOrganizer.logger).to have_received(:warn).with(/TELESCOP header 'Strange Scope' is not in the configured telescope list/)
          expect(AstroSubframeOrganizer.logger).to have_received(:info).with(/consider adding it to 'telescope_ignore_patterns'/)
          expect(prompt).to have_received(:enum_select).with(
            a_string_including("TELESCOP is 'Strange Scope'"),
            ['Strange Scope', 'RedCat51', 'ZhumellZ130'],
          )
        end

        it 'allows accepting the unknown telescope as-is' do
          allow(prompt).to receive(:enum_select).and_return('Strange Scope')
          expect(selector.choose_telescope_or_confirm(detected: 'Strange Scope')).to eq('Strange Scope')
        end
      end

      context 'when no telescope is detected' do
        before do
          allow(prompt).to receive(:enum_select).and_return('RedCat51')
        end

        it 'falls back to the standard telescope prompt' do
          selector.choose_telescope_or_confirm(detected: nil)
          expect(prompt).to have_received(:enum_select).with(
            'What telescope is this set for?',
            telescopes,
          )
        end
      end

      context 'when only one telescope is configured' do
        let(:telescopes) { ['RedCat51'] }

        context 'when TELESCOP header is absent' do
          it 'returns the only configured telescope without prompting' do
            expect(prompt).not_to receive(:enum_select)
            expect(selector.choose_telescope_or_confirm(detected: nil)).to eq('RedCat51')
          end
        end

        context 'when TELESCOP header matches the configured telescope' do
          it 'returns the configured telescope without prompting' do
            expect(prompt).not_to receive(:enum_select)
            expect(selector.choose_telescope_or_confirm(detected: 'RedCat51')).to eq('RedCat51')
          end
        end

        context 'when TELESCOP header is a mount name (ignored) and not in the configured list' do
          it 'returns the only configured telescope without prompting' do
            expect(prompt).not_to receive(:enum_select)
            expect(selector.choose_telescope_or_confirm(detected: 'EQMod Mount')).to eq('RedCat51')
          end

          it 'logs that the mount was ignored and auto-detect failed' do
            selector.choose_telescope_or_confirm(detected: 'EQMod Mount')
            expect(AstroSubframeOrganizer.logger).to have_received(:info).with(/Ignoring detected mount name/)
            expect(AstroSubframeOrganizer.logger).to have_received(:warn).with(/Telescope auto-detect failed/)
          end
        end
      end
    end

    describe '#choose_camera_or_confirm' do
      context 'when camera is already set' do
        before { selector.camera = 'T7' }

        it 'returns the preset camera' do
          expect(selector.choose_camera_or_confirm(detected: 'ASI183')).to eq('T7')
        end
      end

      context 'when detected matches configured list' do
        it 'returns detected directly' do
          expect(selector.choose_camera_or_confirm(detected: '183MC')).to eq('183MC')
        end
      end

      context 'when detected is unknown' do
        it 'prompts to confirm or select' do
          allow(prompt).to receive(:enum_select).and_return('183MC')
          selector.choose_camera_or_confirm(detected: 'Unknown Cam')
          expect(prompt).to have_received(:enum_select).with(
            a_string_including('Unknown Cam'),
            ['Unknown Cam', 'T7', '183MC'],
          )
        end
      end

      context 'when nothing is detected' do
        it 'falls back to standard prompt' do
          allow(prompt).to receive(:enum_select).and_return('T7')
          selector.choose_camera_or_confirm(detected: nil)
          expect(prompt).to have_received(:enum_select).with('What camera is used with this set?', cameras)
        end
      end
    end

    describe '#choose_filter_or_confirm' do
      context 'when filter is already set' do
        before { selector.filter = 'NBZ' }

        it 'returns the preset filter' do
          expect(selector.choose_filter_or_confirm(detected: 'L-Pro')).to eq('NBZ')
        end
      end

      context 'when detected matches configured list' do
        it 'returns detected directly' do
          expect(selector.choose_filter_or_confirm(detected: 'NBZ')).to eq('NBZ')
        end
      end

      context 'when detected is unknown' do
        it 'prompts to confirm or select' do
          allow(prompt).to receive(:enum_select).and_return('NBZ')
          selector.choose_filter_or_confirm(detected: 'Unknown Filter')
          expect(prompt).to have_received(:enum_select).with(
            a_string_including('Unknown Filter'),
            ['Unknown Filter', 'BaaderMoon', 'NBZ'],
          )
        end
      end

      context 'when nothing is detected' do
        it 'falls back to standard prompt' do
          allow(prompt).to receive(:enum_select).and_return('NBZ')
          selector.choose_filter_or_confirm(detected: nil)
          expect(prompt).to have_received(:enum_select).with('What filter is used with this set?', filters)
        end
      end
    end

    describe 'logging' do
      it 'logs the selection for telescope' do
        selector.choose_telescope
        expect(AstroSubframeOrganizer.logger).to have_received(:info).with('Selected Telescope: RedCat51')
      end

      it 'logs the selection for camera' do
        allow(prompt).to receive(:enum_select).and_return('T7')
        selector.choose_camera
        expect(AstroSubframeOrganizer.logger).to have_received(:info).with('Selected Camera: T7')
      end

      it 'logs the selection for filter' do
        allow(prompt).to receive(:enum_select).and_return('BaaderMoon')
        selector.choose_filter
        expect(AstroSubframeOrganizer.logger).to have_received(:info).with('Selected Filter: BaaderMoon')
      end

      it 'logs when prompting for confirmation of unknown equipment' do
        allow(prompt).to receive(:enum_select).and_return('ConfirmedValue')
        selector.choose_camera_or_confirm(detected: 'Unknown')
        expect(AstroSubframeOrganizer.logger).to have_received(:info).with('Selected Camera: ConfirmedValue')
      end

      it 'does not log if the value was already set on the selector' do
        selector.camera = 'T7'
        selector.choose_camera
        expect(AstroSubframeOrganizer.logger).not_to have_received(:info).with(/Selected Camera/)
      end

      it 'logs the selection even when auto-selecting a single option' do
        single_selector = described_class.new(prompt, telescopes: ['SingleScope'], cameras: [], filters: [])
        single_selector.choose_telescope
        expect(AstroSubframeOrganizer.logger).to have_received(:info).with('Selected Telescope: SingleScope')
      end
    end
  end
end
