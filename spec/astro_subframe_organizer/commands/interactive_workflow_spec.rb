# frozen_string_literal: true

require 'spec_helper'
require 'timeout'
require 'stringio'

describe 'Interactive CLI Workflow (In-Process)', type: :aruba do
  let(:test_path) { expand_path('.') }

  # Use a Pipe for stdin so the CLI thread blocks correctly on read
  let(:stdin_pipe) { IO.pipe }
  let(:stdin) { stdin_pipe[0] } # Read end
  let(:stdin_write) { stdin_pipe[1] } # Write end

  # TTY::Screen and others try to call ioctl on stdout/stderr to get window size.
  # StringIO doesn't support ioctl, so we provide a dummy method that returns -1 (failure).
  # This allows TTY tools to fall back to environment variables or defaults.
  def stub_io(io)
    io.define_singleton_method(:ioctl) { |*| -1 }
    io.define_singleton_method(:tty?) { true }
    io.define_singleton_method(:isatty) { true }
    io
  end

  let(:stdout) { stub_io(StringIO.new) }
  let(:stderr) { stub_io(StringIO.new) }

  # This is the key: we run the CLI logic directly in the test process,
  # injecting our StringIO objects for I/O.
  def run_interactive_cli(dry_run: false)
    @read_pointer = 0
    stdout.rewind
    stderr.rewind

    # Use a thread to run the CLI so we can interact with it
    @cli_thread = Thread.new do
      AstroSubframeOrganizer.run(
        dry_run: dry_run,
        path: test_path,
        stdin: stdin,
        stdout: stdout,
        stderr: stderr,
      )
    end

    # Give the CLI a moment to start and print its first prompt
    sleep 0.1
    @cli_thread
  end

  # Helper to read output and assert
  def expect_output(expected_regex, cli_thread = nil)
    @read_pointer ||= 0
    # Use a solid timeout regardless of Aruba global config flakiness
    timeout = [aruba.config.io_wait_timeout, 10].max

    Timeout.timeout(timeout) do
      loop do
        # Early exit if the CLI thread crashed
        raise "CLI thread died unexpectedly:\nStderr: #{stderr.string}\nStdout: #{stdout.string}" if cli_thread && !cli_thread.alive?

        # Look at the buffer starting from where we last left off
        unprocessed_output = stdout.string[@read_pointer..-1] || ''
        if match = unprocessed_output.match(expected_regex)
          # Advance the pointer to the end of this match
          @read_pointer += (match.begin(0) + match[0].length)
          return
        end
        sleep 0.05
      end
    end
  rescue Timeout::Error
    unprocessed_output = stdout.string[@read_pointer..-1] || ''
    raise(
      "Timed out waiting for output matching #{expected_regex.inspect}.\n" \
      "--- Unprocessed buffer ---\n#{unprocessed_output}\n" \
      "--- Full buffer content ---\n#{stdout.string}\n" \
      "--- Stderr ---\n#{stderr.string}",
    )
  end

  # Helper to send input
  def send_input(input_string)
    stdin_write.puts input_string
    stdin_write.flush
  end

  before do
    # Force module prompt reset to prevent cross-test contamination
    AstroSubframeOrganizer.instance_variable_set(:@prompt, nil)
    # Reset Config cache so the "Using config file" message is logged every time
    AstroSubframeOrganizer::Config.instance_variable_set(:@load, nil)

    # Prepare environment with a file that can be renamed then organized
    install_fixture('cr2/dark/IMG_0001.CR2', test_path, dest_path: 'IMG_0001.CR2')
  end

  after do
    # 1. Kill the thread first so it stops trying to read/write
    if @cli_thread
      @cli_thread.kill
      @cli_thread.join(1)
    end
    # 2. Safely close pipes
    stdin_write.close unless stdin_write.closed?
    stdin.close unless stdin.closed?
  end

  it 'navigates through the main menu and handles a Rename sub-menu' do
    cli_thread = run_interactive_cli(dry_run: true)

    # 1. Initial configuration and Main Menu.
    # Match config and menu in sequence to ensure buffer is properly consumed.
    expect_output(/Using config file at.*What are we organizing\?/m, cli_thread)
    send_input '7'

    # 2. Select 'Dark' from Rename Sub-menu (Choice 1)
    expect_output(/What is the file type/i, cli_thread)
    send_input '1'

    # 3. Action Layer: Verify the utility processed the file.
    expect_output(/(Renaming|mv).*IMG_0001/i, cli_thread)

    # 4. Recursion Layer: Verify return to main menu.
    expect_output(/What are we organizing\?/, cli_thread)

    # 5. Exit Layer: Select 'Quit' (Choice 8)
    send_input '8'

    # Wait for the CLI thread to finish
    cli_thread.join(aruba.config.exit_timeout)
    expect(cli_thread).not_to be_alive, 'CLI thread did not exit gracefully.'
  end

  it 'navigates to the "Remove empty directories" utility and returns to menu' do
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/Using config file at.*What are we organizing\?/m, cli_thread)
    send_input '5'

    # Verify utility output and return to menu
    expect_output(/Cleaning up empty directories/, cli_thread)

    # 3. Verify return to main menu.
    expect_output(/What are we organizing\?/, cli_thread)

    # 4. Exit Layer: Select 'Quit' (Choice 8)
    send_input '8'

    # Wait for the CLI thread to finish
    cli_thread.join(aruba.config.exit_timeout)
    expect(cli_thread).not_to be_alive, 'CLI thread did not exit gracefully.'
  end

  it 'organizes dark frames interactively' do
    # Create a dark frame that auto-detects the camera but requires confirmation
    FitsFactory.create(
      File.join(test_path, 'dark.fit'),
      headers: { 'IMAGETYP' => 'Dark', 'EXPOSURE' => 300.0, 'INSTRUME' => '183MC' },
    )
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/What are we organizing\?/, cli_thread)
    send_input '1' # Select Darks

    expect_output(/Continue\?/, cli_thread)
    send_input 'y'

    expect_output(/mv.*dark\.fit/i, cli_thread)
    expect_output(/Done.*What are we organizing\?/m, cli_thread)

    send_input '8' # Quit
    cli_thread.join(aruba.config.exit_timeout)
    expect(cli_thread).not_to be_alive
  end

  it 'organizes flat frames and prompts for missing equipment' do
    # Create a flat frame with missing headers to trigger prompts
    FitsFactory.create(
      File.join(test_path, 'flat.fit'),
      headers: { 'IMAGETYP' => 'Flat', 'EXPOSURE' => 5.0, 'INSTRUME' => nil },
    )
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/What are we organizing\?/, cli_thread)
    send_input '2' # Select Flats

    expect_output(/Continue\?/, cli_thread)
    send_input 'y'

    expect_output(/telescope/i, cli_thread)
    send_input '1' # Select first option (RedCat51)

    expect_output(/What filter/i, cli_thread)
    send_input '1' # Select first option (BaaderMoon)

    expect_output(/What camera/i, cli_thread)
    send_input '2' # Select second option (183MC)

    expect_output(/mv.*flat\.fit/i, cli_thread)
    expect_output(/Done.*What are we organizing\?/m, cli_thread)

    send_input '8'
    cli_thread.join(aruba.config.exit_timeout)
  end

  it 'organizes light frames with mosaic pane detection' do
    # Create a mosaic frame
    FitsFactory.create(
      File.join(test_path, 'Light_M16_1-1_300.0s_Bin1_183MC_gain111_20240713-022314_-10.0C_0003.fit'),
      headers: { 'IMAGETYP' => 'Light', 'OBJECT' => 'M16', 'INSTRUME' => '183MC' },
    )
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/What are we organizing\?/, cli_thread)
    send_input '3' # Select Lights

    expect_output(/Continue\?/, cli_thread)
    send_input 'y'

    expect_output(/telescope/i, cli_thread)
    send_input '1'

    expect_output(/What filter/i, cli_thread)
    send_input '1'

    expect_output(/mv.*PANE_1-1/i, cli_thread)
    expect_output(/Done.*What are we organizing\?/m, cli_thread)

    send_input '8'
    cli_thread.join(aruba.config.exit_timeout)
  end

  it 'organizes bias frames' do
    FitsFactory.create(File.join(test_path, 'bias.fit'), headers: { 'IMAGETYP' => 'Bias', 'EXPOSURE' => 0.000032 })
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/What are we organizing\?/, cli_thread)
    send_input '4' # Select Biases

    expect_output(/Continue\?/, cli_thread)
    send_input 'y'

    # 183MC is auto-detected from the FitsFactory default INSTRUME
    expect_output(/mv.*bias\.fit/i, cli_thread)
    expect_output(/Done.*What are we organizing\?/m, cli_thread)

    send_input '8'
    cli_thread.join(aruba.config.exit_timeout)
  end

  it 'removes thumbnails' do
    FileUtils.touch(File.join(test_path, 'sample_thn.jpg'))
    cli_thread = run_interactive_cli(dry_run: true)

    expect_output(/What are we organizing\?/, cli_thread)
    send_input '6' # Select Remove thumbnails

    expect_output(/Removing jpg thumbnails.*What are we organizing\?/m, cli_thread)

    send_input '8'
    cli_thread.join(aruba.config.exit_timeout)
  end
end
