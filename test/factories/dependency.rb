FactoryBot.define do
  factory :dependency do
    gem_dependency do
      rubygem = Rubygem.last || create(:rubygem)
      Gem::Dependency.new(rubygem.name, "1.0.0")
    end

    rubygem
    version

    trait :runtime

    trait :development do
      gem_dependency do
        rubygem = Rubygem.last || create(:rubygem)
        Gem::Dependency.new(rubygem.name, "1.0.0", :development)
      end
    end

    trait :unresolved do
      gem_dependency { Gem::Dependency.new("unresolved-gem-nothere", "1.0.0") }
      rubygem { nil }
    end
  end
end
