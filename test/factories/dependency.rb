Factory.define :dependency do |dependency|
  dependency.association :rubygem
  dependency.association :version
  dependency.requirements { '>= 1.0' }
  dependency.scope        { 'runtime' }
end

Factory.define :development_dependency, :parent => :dependency do |dependency|
  dependency.scope { 'development' }
end

Factory.define :runtime_dependency, :parent => :dependency do |dependency|
  dependency.scope { 'runtime' }
end
