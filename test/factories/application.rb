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
    approved true
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
  end

  factory :rubygem_with_downloads, :parent => :rubygem do
    after_create do |r|
      $redis[Download.key(r)] = r['downloads']
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
    rubygem
  end

  sequence :url do |n|
    "http://example#{n}.com"
  end

  factory :web_hook do
    rubygem
    url
    user
  end

  factory :global_web_hook, :parent => :web_hook do
    rubygem nil
  end
end
