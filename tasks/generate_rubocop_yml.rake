# frozen_string_literal: true

require "erb"

desc "Generate RuboCop manifest"
task :generate_rubocop_yml do
  print "Generating .rubocop.yml file... "

  template = ::File.read(".rubocop.yml.erb")
  renderer = ::ERB.new(template)

  file = ::File.open(".rubocop.yml", "w")
  file.write(renderer.result)
  file.close

  puts "Done."
end
