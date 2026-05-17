# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Equipment
    describe Camera do
      it 'loads all the default camera items' do
        expect(Camera.all).to contain_exactly(
          'CanonEOS1500D',
          'ZWO ASI183MC Pro',
        )
      end
    end
  end
end
