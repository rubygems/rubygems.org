FactoryBot.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  sequence :handle do |n|
    "handle#{n}"
  end

  factory :user do
    email
    handle
    password { PasswordHelpers::SECURE_TEST_PASSWORD }
    api_key { "secret123" }
    email_confirmed { true }

    trait :mfa_enabled do
      mfa_seed { "123abc" }
      mfa_level { User.mfa_levels["ui_and_api"] }
      mfa_recovery_codes { %w[aaa bbb ccc] }
    end
  end

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

  factory :linkset do
    rubygem
    home { "http://example.com" }
    wiki { "http://example.com" }
    docs { "http://example.com" }
    mail { "http://example.com" }
    code { "http://example.com" }
    bugs { "http://example.com" }
  end

  factory :ownership do
    rubygem
    user
    confirmed_at { Time.current }
    authorizer { user }
    trait :unconfirmed do
      confirmed_at { nil }
    end
  end

  factory :ownership_call do
    rubygem
    user
    note { "small note" }
    trait :closed do
      status { "closed" }
    end
  end

  factory :ownership_request do
    rubygem
    user
    note { "small note here" }
    status { "opened" }
    approver { nil }
    trait :approved do
      approver { user }
      status { "approved" }
    end
    trait :closed do
      status { "closed" }
    end
    trait :with_ownership_call do
      ownership_call
    end
  end

  factory :subscription do
    rubygem
    user
  end

  factory :api_key do
    transient { key { "12345" } }

    user
    name { "ci-key" }

    # enabled by default. disabled when show_dashboard is enabled.
    index_rubygems { show_dashboard ? false : true }

    hashed_key { Digest::SHA256.hexdigest(key) }
  end

  sequence :name do |n|
    "RubyGem#{n}"
  end

  factory :rubygem do
    transient do
      owners { [] }
      number { nil }
      downloads { 0 }
    end

    name

    after(:build) do |rubygem, evaluator|
      if evaluator.linkset
        rubygem.linkset = evaluator.linkset
      else
        build(:linkset, rubygem: rubygem)
      end
    end

    after(:create) do |rubygem, evaluator|
      evaluator.owners.each do |owner|
        create(:ownership, rubygem: rubygem, user: owner)
      end

      create(:version, rubygem: rubygem, number: evaluator.number) if evaluator.number
      GemDownload.increment(evaluator.downloads, rubygem_id: rubygem.id, version_id: 0) if evaluator.downloads
    end
  end

  sequence :number do |n|
    "0.0.#{n}"
  end

  factory :version do
    authors { ["Joe User"] }
    built_at { 1.day.ago }
    description { "Some awesome gem" }
    indexed { true }
    metadata { { "foo" => "bar" } }
    number
    canonical_number { Gem::Version.new(number).canonical_segments.join(".") }
    platform { "ruby" }
    required_rubygems_version { ">= 2.6.3" }
    required_ruby_version { ">= 2.0.0" }
    licenses { "MIT" }
    requirements { "Opencv" }
    rubygem
    size { 1024 }
    # In reality sha256 is different for different version
    # sha256 is calculated in Pusher, we don't use pusher to create versions in tests
    sha256 { "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g=" }

    trait :yanked do
      indexed { false }
    end

    trait :mfa_required do
      metadata { { "rubygems_mfa_required" => "true" } }
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
      rubygem { nil }
    end
  end

  factory :gem_download do
    rubygem_id { 0 }
    version_id { 0 }
    count { 0 }
  end

  factory :sendgrid_event do
    sequence(:sendgrid_id) { |n| "TestSendgridId#{n}" }
    status { "pending" }
    payload { {} }
  end

  factory :gem_typo_exception do
    name
  end

  factory :webauthn_credential do
    user
    sequence(:external_id) { |n| "webauthn-credential-#{n}" }
    public_key { "abc" }
    nickname { "Key #{SecureRandom.hex(24)}" }

    trait :primary

    trait :backup do
      nickname { "Backup key" }
    end
  end

  factory :api_key_rubygem_scope do
    ownership
    api_key { create(:api_key, key: SecureRandom.hex(24)) }
  end
end
