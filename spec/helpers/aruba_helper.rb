# frozen_string_literal: true

require 'aruba/api'

RSpec.configure do |config|
  config.include Aruba::Api, type: :aruba

  config.before type: :aruba do
    Aruba.configure do |config|
      config.command_runtime_environment = {
        'HOME' => config.home_directory,
      }
      # Increase timeouts for Windows CI stability
      config.exit_timeout = 15
      config.io_wait_timeout = 1
    end

    setup_aruba
    prepend_environment_variable 'PATH', "#{File.expand_path('../../exe', __dir__)}#{File::PATH_SEPARATOR}"
  end

  config.after type: :aruba do
    stop_all_commands
    # Give Windows a moment to release file locks on output capture files
    sleep 0.1 if Gem.win_platform?
  end
end
