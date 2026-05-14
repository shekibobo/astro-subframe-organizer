# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Commands
    describe 'astro-subframe-organizer inspect', :files, type: :aruba do
      before do
        run_command_and_stop "astro-subframe-organizer inspect '#{path}'"
      end

      context 'with a fits file' do
        let(:path) { fixture('fits/light-blanks/Light_IC 63_600.0s_Bin1_183MC_gain111_20251113-192818_-10.0C_0001.fit') }

        it 'exits successfully' do
          expect(last_command_started.exit_status).to eq(0)
        end

        it 'prints the fits headers for the file' do
          expect(last_command_started).to have_output eq(<<~OUTPUT.strip)
            FITS Headers: Light_IC 63_600.0s_Bin1_183MC_gain111_20251113-192818_-10.0C_0001.fit
            ────────────────────────────────────────────────────────────
            SIMPLE      T
            BITPIX      16
            NAXIS       0
            NAXIS1      5496
            NAXIS2      3672
            EXTEND      T
            COMMENT     T
            BZERO       32768
            BSCALE      1
            CREATOR     ZWO ASIAIR Plus
            OFFSET      10
            XORGSUBF    0
            YORGSUBF    0
            FOCALLEN    247
            SET-TEMP    -10
            EGAIN       1.008575797
            XBINNING    1
            YBINNING    1
            CCDXBIN     1
            CCDYBIN     1
            XPIXSZ      2.400000095
            YPIXSZ      2.400000095
            IMAGETYP    Light
            EXPOSURE    600
            EXPTIME     600
            CCD-TEMP    -10
            DATE-OBS    2025-11-14T00:18:17.205829
            INSTRUME    ZWO ASI183MC Pro
            GUIDECAM    ZWO ASI120MM Mini
            BAYERPAT    RGGB
            GAIN        111
            FOCUSPOS    888
            TELESCOP    EQMod Mount
            OBJECT      IC 63
            IMAGEW      5496
            IMAGEH      3672
          OUTPUT
        end
      end

      context 'with a raw cr2 file' do
        let(:path) { fixture('cr2/IMG_0001.CR2') }

        it 'exits successfully' do
          expect(last_command_started.exit_status).to eq(0)
        end

        it 'prints the fits headers for the file' do
          expect(last_command_started).to have_output an_output_string_including(<<~OUTPUT.strip)
            EXIF Data: IMG_0001.CR2
            ────────────────────────────────────────────────────────────
            AEB Bracket Value               0
            AF Area Heights                 800 0 0 0 0 0 0 0 0
            AF Area Mode                    Off (Manual Focus)
            AF Area Widths                  1200 0 0 0 0 0 0 0 0
            AF Area X Positions             0 0 0 0 0 0 0 0 0
            AF Area Y Positions             -168 0 0 0 0 0 0 0 0
            AF Assist Beam                  Emits
            AF Image Height                 4000
            AF Image Width                  6000
            AF Points In Focus              (none)
            AF Points Selected              0
            Ambience Selection              Standard
            Aperture                        11
            Aperture Value                  11.3
          OUTPUT
        end
      end
    end
  end
end
