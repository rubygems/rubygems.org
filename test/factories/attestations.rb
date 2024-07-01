FactoryBot.define do
  factory :attestation do
    version
    body { "{}" }
    media_type { Sigstore::BundleType::BUNDLE_0_3 }
  end
end
