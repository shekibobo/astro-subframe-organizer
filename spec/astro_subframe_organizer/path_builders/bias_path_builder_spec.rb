# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe BiasPathBuilder, :files do
      let(:path) { fixture('fits/bias-blanks/Bias_250.0us_Bin1_ISO800_20220916-150614_37.0C_0012.fit') }

      # TODO: Fix sub-second exposure parsing on header parser
      it 'builds a target directory path including matching keywords for Bias frames' do
        metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
        metadata.camera = 'T7'
        builder = BiasPathBuilder.new(metadata)

        target_dir = builder.build

        expect(target_dir).to eq('Bias_ISO_800_EXP_250.0us_Bin_1_CAMERA_T7_MONTH_2022-11')
      end
    end
  end
end
