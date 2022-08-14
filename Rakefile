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

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-gitlab-security"
  task.requires << "rubocop-md"
  task.requires << "rubocop-performance"
  task.requires << "rubocop-rake"
  task.requires << "rubocop-rspec"
  task.requires << "rubocop-thread_safety"
end

YARD::Rake::YardocTask.new

Dir["tasks/**/*.rake"].each { |t| load t }

task default: %i[
  generate_rubocop_yml
  rubocop:autocorrect
  test
  yard
]
