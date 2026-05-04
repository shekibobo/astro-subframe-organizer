# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe DarkPathBuilder, :files do
      describe 'darks for lights' do
        let(:path) { fixture('fits/dark-blanks/Dark_180.0s_Bin1_183MC_gain111_20260411-215400_-10.0C_0025.fit') }

        it 'builds a target directory path including matching keywords for Dark frames' do
          metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
          builder = DarkPathBuilder.new(metadata)

          target_dir = builder.build

          expect(target_dir).to eq('Dark_GAIN_111_EXP_180.0s_CCD-TEMP_-10.0C_CAMERA_ZWO ASI183MC Pro_MONTH_2026-04')
        end
      end

      describe 'darks for flats' do
        let(:path) { fixture('fits/dark-blanks/Dark_5.0s_Bin1_183MC_gain111_20260411-144955_-10.0C_0006.fit') }

        it 'builds a target directory path including matching keywords for Flat-Dark frames' do
          metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
          metadata.dark_flat = true
          builder = DarkPathBuilder.new(metadata)

          target_dir = builder.build

          expect(target_dir).to eq('DarkFlat_FLATSET_20260411_GAIN_111_EXP_5.0s_Bin_1_CAMERA_ZWO ASI183MC Pro')
        end
      end
    end
  end
end
