# frozen_string_literal: true

require 'aruba/api'

RSpec.configure do |config|
  config.include Aruba::Api, type: :aruba

  config.before type: :aruba do
    Aruba.configure do |config|
      config.command_runtime_environment = {
        'HOME' => config.home_directory,
      }
    end

    setup_aruba
    prepend_environment_variable 'PATH', "#{File.expand_path('../../exe', __dir__)}#{File::PATH_SEPARATOR}"
  end
end
