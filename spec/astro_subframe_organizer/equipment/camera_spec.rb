# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Equipment
    describe Camera do
      it 'loads all the default camera items' do
        expect(Camera.all).to contain_exactly(
          '183MC',
          'Canon EOS 1500D',
          'T7',
          'ZWO ASI183MC Pro',
        )
      end
    end
  end
end
