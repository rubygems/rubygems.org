Factory.define :rubygem do |rubygem|
  rubygem.name       { 'RGem' }
  rubygem.token      { 'asdf' }
  rubygem.association :user
end
