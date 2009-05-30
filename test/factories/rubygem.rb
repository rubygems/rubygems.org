Factory.define :rubygem do |rubygem|
  rubygem.name        { 'RGem' }
  rubygem.token       { 'asdf' }
  rubygem.association :user
  rubygem.spec        { gem_spec }
  rubygem.path        { gem_file.path }
end
