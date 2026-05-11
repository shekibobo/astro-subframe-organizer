# frozen_string_literal: true

require 'spec_helper'

module AstroSubframeOrganizer
  module Equipment
    describe Camera do
      it 'loads all the default camera items' do
        expect(Camera.all).to contain_exactly(
          'T7',
          '183MC',
        )
      end
    end
  end
end
