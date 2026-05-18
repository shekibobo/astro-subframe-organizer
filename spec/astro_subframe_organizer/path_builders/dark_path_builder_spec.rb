# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe DarkPathBuilder, :files do
      def build_path(ccd_temp:, dark_flat: false, **kwargs)
        metadata = FileMetadata.new(
          type: dark_flat ? 'DarkFlat' : 'Dark',
          path: 'dark.fit',
          filename: 'dark.fit',
          file_format: :fits,
          ccd_temp: ccd_temp,
          exposure: '300.0s',
          gain: 111,
          camera: '183MC',
          created_at: DateTime.new(2026, 4, 11, 13, 0, 0),
          dark_flat: dark_flat,
          **kwargs,
        )
        described_class.new(metadata).build
      end

      describe 'darks for lights' do
        let(:path) { fixture('fits/dark-blanks/Dark_180.0s_Bin1_183MC_gain111_20260411-215400_-10.0C_0025.fit') }

        it 'builds a target directory path including matching keywords for Dark frames' do
          metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
          builder = described_class.new(metadata)

          target_dir = builder.build

          expect(target_dir).to eq('Dark_GAIN_111_EXP_180.0s_CCD-TEMP_-10._CAMERA_ZWO ASI183MC Pro_MONTH_2026-04')
        end
      end

      describe 'darks for flats' do
        let(:path) { fixture('fits/dark-blanks/Dark_5.0s_Bin1_183MC_gain111_20260411-144955_-10.0C_0006.fit') }

        it 'builds a target directory path including matching keywords for Flat-Dark frames' do
          metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
          metadata.dark_flat = true
          builder = described_class.new(metadata)

          target_dir = builder.build

          expect(target_dir).to eq('DarkFlat_FLATSET_20260411_GAIN_111_EXP_5.0s_Bin_1_CAMERA_ZWO ASI183MC Pro')
        end
      end

      describe 'temperature grouping in dark path' do
        context 'with default tolerance of 5 degrees' do
          it 'groups -9.5C and -10.0C into the same directory' do
            expect(build_path(ccd_temp: '-9.5C')).to eq(build_path(ccd_temp: '-10.0C'))
          end

          it 'groups -10.0C and -10.5C into the same directory' do
            expect(build_path(ccd_temp: '-10.5C')).to eq(build_path(ccd_temp: '-10.0C'))
          end

          it 'does not group -10.0C and -15.0C together' do
            expect(build_path(ccd_temp: '-10.0C')).not_to eq(build_path(ccd_temp: '-15.0C'))
          end

          it 'includes the rounded temperature in the path' do
            expect(build_path(ccd_temp: '-9.5C')).to include('CCD-TEMP_-10.')
          end

          it 'does not include the raw temperature in the path' do
            expect(build_path(ccd_temp: '-9.5C')).not_to include('CCD-TEMP_-9.5')
          end
        end

        context 'with tolerance of 1 degree from config' do
          before { allow(Config).to receive(:temperature_tolerance).and_return(1.0) }

          it 'keeps -9.5C and -10.5C in separate directories' do
            expect(build_path(ccd_temp: '-9.5C')).not_to eq(build_path(ccd_temp: '-10.5C'))
          end

          it 'groups -9.5C with -10.0C' do
            expect(build_path(ccd_temp: '-9.5C')).to eq(build_path(ccd_temp: '-10.0C'))
          end
        end

        context 'with tolerance of 10 degrees from config' do
          before { allow(Config).to receive(:temperature_tolerance).and_return(10.0) }

          it 'groups -9.5C and -14.9C into the same directory' do
            expect(build_path(ccd_temp: '-9.5C')).to eq(build_path(ccd_temp: '-14.9C'))
          end

          it 'does not group -10.0C and -20.0C together' do
            expect(build_path(ccd_temp: '-10.0C')).not_to eq(build_path(ccd_temp: '-20.0C'))
          end
        end
      end
    end
  end
end
