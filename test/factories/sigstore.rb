FactoryBot.define do
  factory :sigstore_x509_certificate, class: "Sigstore::Common::V1::X509Certificate" do
    transient do
      x509_certificate factory: %i[x509_certificate key_usage github_actions_fulcio]
    end
    initialize_with do
      cert = new
      cert.raw_bytes = x509_certificate.to_der
      cert
    end
    to_create { |instance| instance }
  end
  factory :sigstore_verification_material, class: "Sigstore::Bundle::V1::VerificationMaterial" do
    certificate factory: %i[sigstore_x509_certificate]
    tlog_entries { [build(:sigstore_tlog_entry)] }
    to_create { |instance| instance }
  end
  factory :sigstore_checkpoint, class: "Sigstore::Rekor::V1::Checkpoint" do
    to_create { |instance| instance }
  end
  factory :sigstore_inclusion_proof, class: "Sigstore::Rekor::V1::InclusionProof" do
    checkpoint factory: %i[sigstore_checkpoint]
    to_create { |instance| instance }
  end
  factory :sigstore_tlog_entry, class: "Sigstore::Rekor::V1::TransparencyLogEntry" do
    sequence(:log_index)
    inclusion_proof factory: %i[sigstore_inclusion_proof]
    to_create { |instance| instance }
  end

  factory :sigstore_bundle, class: "Sigstore::Bundle::V1::Bundle" do
    media_type { Sigstore::BundleType::BUNDLE_0_3.media_type }
    verification_material factory: %i[sigstore_verification_material]
    to_create { |instance| instance }
  end
end
