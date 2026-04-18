# frozen_string_literal: true

require_relative '../../test_helper'

class TestBiasPathBuilder < AstroSubframeOrganizer::Test
  def test_builds_bias_path
    photo = Astrophoto.new('/fake/Bias_0.0s_Bin1_T7_ISO100_20220508-120000_-10.0C_0001.fit')
    builder = BiasPathBuilder.new(photo)

    target_dir = builder.build

    assert_match(/^Bias_ISO_100/, target_dir)
    assert_match(/EXP_0\.0s/, target_dir)
    assert_match(/Bin_1/, target_dir)
    assert_match(/CAMERA_T7/, target_dir)
    assert_match(/MONTH_2022-05$/, target_dir)
  end
end
