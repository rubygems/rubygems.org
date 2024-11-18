FactoryBot.define do
  factory :attestation do
    version
    media_type { Sigstore::BundleType::BUNDLE_0_3.media_type }
    body factory: %i[sigstore_bundle]
  end
end
