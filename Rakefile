# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rubocop/rake_task"
require "yard"

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.verbose = true
  t.warning = true
end

RuboCop::RakeTask.new

YARD::Rake::YardocTask.new

Dir["tasks/**/*.rake"].each { |t| load t }

task default: %i[
  rubocop:autocorrect
  test
  yard
]
