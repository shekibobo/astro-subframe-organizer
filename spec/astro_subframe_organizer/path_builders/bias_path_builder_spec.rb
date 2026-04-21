# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module PathBuilders
    describe BiasPathBuilder do
      it 'builds a target directory path including matching keywords for Bias frames' do
        photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
        builder = BiasPathBuilder.new(photo)

        target_dir = builder.build

        expect(target_dir).to eq('Bias_ISO_100_EXP_0.0s_Bin_1_CAMERA_T7_MONTH_2022-05')
      end
    end
  end
end
