FactoryGirl.define do
  factory :dependency do
    gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0") }
    rubygem # { Factory(:rubygem) }
    version
  end

  factory :development_dependency, :parent => :dependency do
    gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0", :development) }
  end

  factory :runtime_dependency, :parent => :dependency do
  end
end
