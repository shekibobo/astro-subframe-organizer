# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

describe 'astro-subframe-organizer bias', type: :aruba do
  include_examples 'an organize command', command: 'bias', type: 'bias'
  include_examples 'an organize command with equipment options', command: 'bias'
end
