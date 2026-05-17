# frozen_string_literal: true

require 'aruba/api'

RSpec.configure do |config|
  config.include Aruba::Api, type: :aruba

  config.before type: :aruba do
    Aruba.configure do |config|
      # Clear Bundler env vars to avoid "No such file or directory - getcwd" errors
      # when the sub-process tries to evaluate the gemspec.
      env = {
        'HOME' => config.home_directory,
        'RSPEC_RUNNING' => 'true',
        'TERM' => 'dumb',
        'LINES' => '80',
        'COLUMNS' => '120',
      }
      %w[BUNDLE_GEMFILE BUNDLE_BIN_PATH RUBYOPT RUBYLIB].each { |key| env[key] = nil }

      config.command_runtime_environment = env

      # Increase timeouts for Windows CI stability
      config.exit_timeout = 30
      config.io_wait_timeout = 10
    end

    # Ensure the local helper context also uses the longer timeout
    aruba.config.io_wait_timeout = 10

    setup_aruba
    prepend_environment_variable 'PATH', "#{File.expand_path('../../exe', __dir__)}#{File::PATH_SEPARATOR}"
  end

  config.after type: :aruba do
    stop_all_commands
    # Give Windows a moment to release file locks on output capture files
    sleep 0.5 if Gem.win_platform?
  end
end
