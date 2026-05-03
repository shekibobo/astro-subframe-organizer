# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe FlatPathBuilder, :files do
      let(:path) { fixture('fits/flat-blanks/Flat_293deg_5.0s_Bin1_183MC_gain111_20251224-111613_-10.0C_0012.fit') }

      it 'builds a target directory path including matching keywords for Flat frames' do
        metadata = AstroSubframeOrganizer::FilenameParsers::FitsHeaderParser.new(path).parse
        metadata.telescope = 'RedCat51'
        metadata.filter = 'BaaderMoon'
        builder = FlatPathBuilder.new(metadata)

        target_dir = builder.build

        # expect(target_dir).to eq('Flat_FLATSET_20251224_GAIN_111_EXP_5.0s_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_T7')
        expect(target_dir).to eq('Flat_FLATSET_20251224_GAIN_111_EXP_5.0_Bin_1_TELESCOPE_RedCat51_FILTER_BaaderMoon_CAMERA_ZWO ASI183MC Pro')
      end
    end
  end
end
