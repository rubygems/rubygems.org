Factory.define :dependency do |dependency|
  dependency.association :rubygem
  dependency.association :version
  dependency.requirements { '>= 1.0' }
end
