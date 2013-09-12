#!/usr/bin/env ruby

# This script is used by the Tree model to capture
# the dependency tree for a Version.  This script is used to
# allow Bundler to run outside of the context of the Rails app
# so that we can get a clean gemset.

require 'rubygems'
require 'bundler'
require 'json'

definition = Bundler.definition(true)
specs = definition.resolve_remotely!

data = []

specs.each do |spec|
  data << {
    :name => spec.name,
    :version => spec.version,
    :dependencies => spec.dependencies.map do |dep|
      #spec = dep.to_spec
      {
        :name => dep.name,
        :requirement => dep.requirement,
        :type => dep.type
      }
    end
  }
end

File.open('data.json', 'w') {|f| f.write(data.to_json) }

#puts "capture_specs : specs.length = #{specs.length}"
