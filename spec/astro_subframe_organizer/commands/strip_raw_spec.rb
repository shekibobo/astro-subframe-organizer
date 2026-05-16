# frozen_string_literal: true

require 'spec_helper'

describe 'bin/strip_raw', type: :aruba do
  let(:test_path) { expand_path('.') }
  let(:input_file) { 'test.CR2' }
  let(:output_dir) { 'stripped_output' }

  before do
    # Prepare a test file from fixtures using the provided helper
    install_fixture('cr2/unstripped/IMG_0001.CR2', test_path, dest_path: input_file)
  end

  it 'executes the stripping process via CLI' do
    # Skip if exiftool isn't available to avoid breaking build environments
    executable = Gem.win_platform? ? 'exiftool.exe' : 'exiftool'
    skip 'exiftool not installed on this system' unless system("#{executable} -ver > /dev/null 2>&1")

    original_size = File.size(File.join(test_path, input_file))

    run_command_and_stop "strip_raw -o #{output_dir} #{input_file}"

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.output).to include("#{input_file}:")

    stripped_file = File.join(test_path, output_dir, input_file)
    expect(File.exist?(stripped_file)).to be true
    expect(File.size(stripped_file)).to be < original_size
  end
end
