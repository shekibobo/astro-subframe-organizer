# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

describe 'astro-subframe-organizer dark', type: :aruba do
  include_examples 'an organize command', command: 'dark', type: 'dark'
  include_examples 'an organize command with equipment options', command: 'dark'
end
