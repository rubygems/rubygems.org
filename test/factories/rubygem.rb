Factory.define :rubygem do |rubygem|
  rubygem.name        { 'RGem' }
  rubygem.token       { 'asdf' }
  rubygem.data        { gem_file("test-0.0.0.gem") }
  rubygem.association :user
end
