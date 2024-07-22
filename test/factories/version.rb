FactoryBot.define do
  factory :version do
    authors { ["Joe User"] }
    built_at { 1.day.ago }
    description { "Some awesome gem" }
    indexed { true }
    metadata { { "foo" => "bar" } }
    number
    canonical_number { Gem::Version.new(number).canonical_segments.join(".") }
    platform { "ruby" }
    gem_platform { Gem::Platform.new(platform).to_s }
    required_rubygems_version { ">= 2.6.3" }
    required_ruby_version { ">= 2.0.0" }
    licenses { "MIT" }
    requirements { "Opencv" }
    rubygem
    size { 1024 }
    # In reality sha256 is different for different version
    # sha256 is calculated in Pusher, we don't use pusher to create versions in tests
    sha256 { "tdQEXD9Gb6kf4sxqvnkjKhpXzfEE96JucW4KHieJ33g=" }
    spec_sha256 { Digest::SHA2.base64digest("#{rubygem.name}-#{number}-#{platform}") }

    trait :yanked do
      indexed { false }
    end

    trait :mfa_required do
      metadata { { "rubygems_mfa_required" => "true" } }
    end

    after(:create) do |version|
      if version.info_checksum.blank?
        checksum = GemInfo.new(version.rubygem.name).info_checksum
        version.update_attribute :info_checksum, checksum
      end
    end
  end
end
