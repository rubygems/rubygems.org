Factory.sequence(:name) { |n| "RubyGem#{n}" }

Factory.define :rubygem do |rubygem|
  rubygem.name        { Factory.next(:name) }
  rubygem.spec        { gem_spec }
  rubygem.path        { gem_file.path }
end
