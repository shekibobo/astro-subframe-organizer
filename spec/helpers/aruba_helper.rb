# frozen_string_literal: true

require 'aruba/api'

module ArubaHelper
  def install_fixture_file(fixture_path:, aruba_path: fixture_path)
    FileUtils.cp(
      File.join(File.expand_path('spec/fixtures'), fixture_path),
      File.join(Aruba.config.home_directory, aruba_path),
    )
    "~/#{aruba_path}"
  end
end

RSpec.configure do |config|
  config.include Aruba::Api, type: :aruba
  config.include ArubaHelper, files: true

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
