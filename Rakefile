# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*_test.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Run unit tests and RuboCop'
task default: %i[test rubocop]
