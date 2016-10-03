FactoryGirl.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  sequence :handle do |n|
    "handle#{n}"
  end

  factory :user do
    email
    handle
    password "password12345"
    api_key "secret123"
  end

  factory :dependency do
    gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0") }
    rubygem
    version

    trait :runtime do
    end

    trait :development do
      gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0", :development) }
    end

    trait :unresolved do
      gem_dependency { Gem::Dependency.new("unresolved-gem-nothere", "1.0.0") }
    end
  end

  factory :linkset do
    home 'http://example.com'
    wiki 'http://example.com'
    docs 'http://example.com'
    mail 'http://example.com'
    code 'http://example.com'
    bugs 'http://example.com'
  end

  factory :ownership do
    rubygem
    user
  end

  factory :subscription do
    rubygem
    user
  end

  sequence :name do |n|
    "RubyGem#{n}"
  end

  factory :rubygem do
    transient do
      owners []
      number nil
      downloads 0
    end

    linkset
    name

    after(:create) do |rubygem, evaluator|
      evaluator.owners.each do |owner|
        create(:ownership, rubygem: rubygem, user: owner)
      end

      if evaluator.number
        create(:version, rubygem: rubygem, number: evaluator.number)
      end

      if evaluator.downloads
        GemDownload.increment(evaluator.downloads, rubygem_id: rubygem.id, version_id: 0)
      end
    end
  end

  sequence :number do |n|
    "0.0.#{n}"
  end

  factory :version do
    authors ["Joe User"]
    built_at 1.day.ago
    description "Some awesome gem"
    indexed true
    metadata "foo" => "bar"
    number
    platform "ruby"
    required_rubygems_version ">= 2.6.3"
    required_ruby_version ">= 2.0.0"
    licenses "MIT"
    requirements "Opencv"
    rubygem
    size 1024
    # In reality sha256 is different for different version
    # sha256 is calculated in Pusher, we don't use pusher to create versions in tests
    sha256 "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g="

    trait :yanked do
      indexed false
    end
  end

  sequence :url do |n|
    "http://example#{n}.com"
  end

  factory :web_hook do
    rubygem
    url
    user

    factory :global_web_hook do
      rubygem nil
    end
  end

  factory :gem_download do
    rubygem_id 0
    version_id 0
    count 0
  end
end
