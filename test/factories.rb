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
    password "password"
  end

  factory :dependency do
    gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0") }
    rubygem
    version

    factory :development_dependency do
      gem_dependency { Gem::Dependency.new(Rubygem.last.name, "1.0.0", :development) }
    end

    factory :runtime_dependency do
    end

    factory :unresolved_dependency do
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

  factory :rubyforger do
    email
    encrypted_password Digest::SHA1.hexdigest("password")
  end

  factory :subscription do
    rubygem
    user
  end

  sequence :name do |n|
    "RubyGem#{n}"
  end

  factory :rubygem do
    linkset
    name

    factory :rubygem_with_downloads do
      after(:create) do |r|
        $redis[Download.key(r)] = r['downloads']
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
    number
    platform "ruby"
    ruby_version ">= 2.0.0"
    licenses "MIT"
    requirements "Opencv"
    rubygem
    size 1024
    sha256 "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g="
  end

  factory :version_history do
    day { Time.zone.today.to_s }
    count 1
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
end
