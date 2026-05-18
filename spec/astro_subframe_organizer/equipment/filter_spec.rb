# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Equipment
    describe Filter do
      it 'loads all the default filter items' do
        expect(described_class.all).to contain_exactly(
          'BaaderMoon',
          'NBZ',
          'NoFilter',
        )
      end
    end
  end
end
