# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

describe 'astro-subframe-organizer light', type: :aruba do
  include_examples 'an organize command', command: 'light', type: 'light'
  include_examples 'an organize command with equipment options', command: 'light'
end
