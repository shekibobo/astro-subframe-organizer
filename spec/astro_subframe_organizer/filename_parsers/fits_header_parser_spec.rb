# frozen_string_literal: true

require 'spec_helper'
require 'astro_subframe_organizer/filename_parsers/fits_header_parser'

module AstroSubframeOrganizer
  module FilenameParsers
    describe FitsHeaderParser do
      # Sample headers derived from a real ZWO ASI183MC Pro light frame captured
      # with ASIAIR Plus. FILTER is absent because this is an OSC camera.
      # TELESCOP contains the mount name rather than the OTA.
      SAMPLE_HEADERS = {
        'SIMPLE' => true,
        'BITPIX' => 16,
        'NAXIS' => 2,
        'NAXIS1' => 5496,
        'NAXIS2' => 3672,
        'EXTEND' => true,
        'BZERO' => 32_768,
        'BSCALE' => 1,
        'CREATOR' => 'ZWO ASIAIR Plus',
        'OFFSET' => 10,
        'FOCALLEN' => 247,
        'SET-TEMP' => -10,
        'EGAIN' => 1.00857579708099,
        'XBINNING' => 1,
        'YBINNING' => 1,
        'CCDXBIN' => 1,
        'CCDYBIN' => 1,
        'XPIXSZ' => 2.40000009536743,
        'YPIXSZ' => 2.40000009536743,
        'IMAGETYP' => 'Light',
        'EXPOSURE' => 300.0,
        'EXPTIME' => 300.0,
        'CCD-TEMP' => -10.0,
        'RA' => 319.739055,
        'DEC' => 43.852758,
        'DATE-OBS' => '2025-09-08T02:46:15.614262',
        'INSTRUME' => 'ZWO ASI183MC Pro',
        'GUIDECAM' => 'ZWO ASI120MM Mini',
        'BAYERPAT' => 'RGGB',
        'GAIN' => 111,
        'FOCUSPOS' => 669,
        'TELESCOP' => 'EQMod Mount',
        'OBJECT' => '68 Cygni',
        'IMAGEW' => 5496,
        'IMAGEH' => 3672,
      }.freeze

      subject(:parser) { described_class.new('/path/to/light_68cygni_0001.fit') }

      before do
        allow(FitsParser).to receive(:new).and_return(fits_parser_double)
        allow(fits_parser_double).to receive(:parse_hdus).and_return([{ header: headers }])
      end

      let(:fits_parser_double) { instance_double(FitsParser) }
      let(:headers)            { SAMPLE_HEADERS.dup }

      describe '#initialize' do
        it 'loads headers from the FITS file' do
          expect(parser.headers).to eq(SAMPLE_HEADERS)
        end

        context 'when no HDU with headers is found' do
          before do
            allow(fits_parser_double).to receive(:parse_hdus).and_return([{}])
          end

          it 'raises an error' do
            expect { parser }.to raise_error(RuntimeError, /No HDU with headers found/)
          end
        end
      end

      describe '#[]' do
        it 'provides direct header access by key' do
          expect(parser['IMAGETYP']).to eq('Light')
        end

        it 'returns nil for absent keys' do
          expect(parser['FILTER']).to be_nil
        end
      end

      describe '#parse' do
        subject(:metadata) { parser.parse }

        it 'returns a FileMetadata instance' do
          expect(metadata).to be_a(FileMetadata)
        end

        it 'sets the file format to :fits' do
          expect(metadata.file_format).to eq(:fits)
        end

        it 'sets the path' do
          expect(metadata.path).to eq('/path/to/light_68cygni_0001.fit')
        end

        it 'sets the filename' do
          expect(metadata.filename).to eq('light_68cygni_0001.fit')
        end

        describe 'image type' do
          it 'reads IMAGETYP from headers' do
            expect(metadata.type).to eq('Light')
          end
        end

        describe 'target' do
          context 'when frame is a light frame' do
            it 'reads OBJECT from headers' do
              expect(metadata.target).to eq('68 Cygni')
            end
          end

          context 'when frame is not a light frame' do
            before { headers['IMAGETYP'] = 'Dark' }

            it 'does not set target' do
              expect(metadata.target).to be_nil
            end
          end
        end

        describe 'telescope' do
          it 'reads TELESCOP from headers' do
            expect(metadata.telescope).to eq('EQMod Mount')
          end
        end

        describe 'filter' do
          context 'when FILTER header is absent (OSC camera)' do
            it 'returns nil' do
              expect(metadata.filter).to be_nil
            end
          end

          context 'when FILTER header is present (mono camera)' do
            before { headers['FILTER'] = 'Ha' }

            it 'reads FILTER from headers' do
              expect(metadata.filter).to eq('Ha')
            end
          end
        end

        describe 'exposure' do
          it 'reads EXPOSURE from headers' do
            expect(metadata.exposure).to eq('300.0s')
          end
        end

        describe 'binning' do
          it 'reads XBINNING from headers' do
            expect(metadata.bin).to eq(1)
          end
        end

        describe 'camera' do
          it 'reads INSTRUME from headers' do
            expect(metadata.camera).to eq('ZWO ASI183MC Pro')
          end
        end

        describe 'gain' do
          it 'reads GAIN from headers' do
            expect(metadata.gain).to eq(111)
          end
        end

        describe 'date' do
          it 'parses DATE-OBS with microsecond precision' do
            expect(metadata.created_at).to eq(DateTime.parse('2025-09-08T02:46:15.614262'))
          end

          context 'when DATE-OBS has no fractional seconds' do
            before { headers['DATE-OBS'] = '2025-09-08T02:46:15' }

            it 'falls back to DateTime.parse' do
              expect(metadata.created_at).to eq(DateTime.parse('2025-09-08T02:46:15'))
            end
          end

          context 'when DATE-OBS is absent' do
            before { headers.delete('DATE-OBS') }

            it 'returns nil' do
              expect(metadata.created_at).to be_nil
            end
          end
        end

        describe 'temperature' do
          it 'reads CCD-TEMP from headers' do
            expect(metadata.ccd_temp).to eq(-10.0)
          end
        end

        describe 'dark_flat' do
          context 'when path includes DarkFlat' do
            subject(:parser) { described_class.new('/path/to/DarkFlat/frame_0001.fit') }

            it 'sets dark_flat to true' do
              expect(metadata.dark_flat).to be true
            end
          end

          context 'when path does not include DarkFlat' do
            it 'sets dark_flat to false' do
              expect(metadata.dark_flat).to be false
            end
          end
        end

        describe 'error handling' do
          context 'when a header raises an error during parsing' do
            before do
              allow(parser).to receive(:image_type).and_raise(StandardError, 'unexpected error')
            end

            it 'returns a FileMetadata with basic file info' do
              expect(metadata).to be_a(FileMetadata)
              expect(metadata.path).to eq('/path/to/light_68cygni_0001.fit')
            end

            it 'does not raise' do
              expect { metadata }.not_to raise_error
            end
          end
        end
      end
      describe '#rotation_angle' do
        context 'when ROTATANG is present' do
          before { headers['ROTATANG'] = 45.0 }

          it 'returns the rotation angle from ROTATANG' do
            expect(parser.rotation_angle).to eq(45.0)
          end
        end

        context 'when ANGLE is present' do
          before { headers['ANGLE'] = 90.0 }

          it 'returns the rotation angle from ANGLE' do
            expect(parser.rotation_angle).to eq(90.0)
          end
        end

        context 'when POSANGLE is present' do
          before { headers['POSANGLE'] = 180.0 }

          it 'returns the rotation angle from POSANGLE' do
            expect(parser.rotation_angle).to eq(180.0)
          end
        end

        context 'when ROTATOR is present' do
          before { headers['ROTATOR'] = 270.0 }

          it 'returns the rotation angle from ROTATOR' do
            expect(parser.rotation_angle).to eq(270.0)
          end
        end

        context 'when multiple rotation headers are present' do
          before do
            headers['ROTATANG'] = 45.0
            headers['ANGLE']    = 90.0
          end

          it 'returns the value from the highest priority header' do
            expect(parser.rotation_angle).to eq(45.0)
          end
        end

        context 'when rotation angle is zero' do
          before { headers['ROTATANG'] = 0.0 }

          it 'returns zero rather than nil' do
            expect(parser.rotation_angle).to eq(0.0)
          end
        end

        context 'when no rotation headers are present' do
          before { FitsHeaderParser::ROTATION_HEADERS.each { |key| headers.delete(key) } }

          it 'returns nil' do
            expect(parser.rotation_angle).to be_nil
          end
        end
      end
    end
  end
end
