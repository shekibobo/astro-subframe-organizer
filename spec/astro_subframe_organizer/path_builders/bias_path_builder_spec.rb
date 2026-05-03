# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe BiasPathBuilder, :files do
      let(:path) { fixture('fits/bias-blanks/Bias_32.0us_Bin1_183MC_gain111_20221229-095040_-10.0C_0010.fit') }

      # TODO: Fix sub-second exposure parsing on header parser
      it 'builds a target directory path including matching keywords for Bias frames' do
        metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
        builder = BiasPathBuilder.new(metadata)

        target_dir = builder.build

        expect(target_dir).to eq('Bias_GAIN_111_EXP_32.0us_Bin_1_CAMERA_ZWO ASI183MC Pro_MONTH_2022-12')
      end
    end
  end
end
