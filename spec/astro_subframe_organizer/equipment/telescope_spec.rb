# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Equipment
    describe Telescope do
      it 'loads all the default telescope items' do
        expect(Telescope.all).to contain_exactly(
          'RedCat51',
          'ZhumellZ130',
          'AperturaAD8',
          'MeadeDS90',
          'CanonEFS1855',
        )
      end
    end
  end
end
