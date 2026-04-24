# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

describe 'astro-subframe-organizer flat', type: :aruba do
  include_examples 'an organize command', command: 'flat', type: 'flat'
  include_examples 'an organize command with equipment options', command: 'flat'
end
