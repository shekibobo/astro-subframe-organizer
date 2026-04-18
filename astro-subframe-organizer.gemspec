# frozen_string_literal: true

require_relative 'lib/astro_subframe_organizer/version'

Gem::Specification.new do |spec|
  spec.name          = 'astro-subframe-organizer'
  spec.version       = AstroSubframeOrganizer::VERSION
  spec.authors       = ['Joshua Kovach']
  spec.email         = ['kovach.jc@gmail.com']

  spec.summary       = 'Organize astrophotography FITS and CR2 files for PixInsight WBPP'
  spec.description   = "A command-line tool to sort and rename astrophotography data based on metadata, facilitating use with PixInsight's WeightedBatchPreProcessing."
  spec.homepage      = 'https://github.com/shekibobo/astro-subframe-organizer'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.2.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/shekibobo/astro-subframe-organizer'
  spec.metadata['changelog_uri'] = 'https://github.com/shekibobo/astro-subframe-organizer/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['lib/**/*.rb'] + ['bin/astro-subframe-organizer', 'README.md', 'LICENSE']
  spec.bindir        = 'bin'
  spec.executables   = ['astro-subframe-organizer']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_runtime_dependency 'highline', '~> 2.0'
  spec.add_runtime_dependency 'mini_exiftool', '~> 2.10'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
