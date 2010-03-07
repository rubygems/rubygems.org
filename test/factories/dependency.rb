Factory.define :dependency do |dependency|
  dependency.rubygem { Factory(:rubygem) }
  dependency.association :version
  dependency.gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0") }
end

Factory.define :development_dependency, :parent => :dependency do |dependency|
  dependency.gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0", :development) }
end

Factory.define :runtime_dependency, :parent => :dependency do |dependency|
end
