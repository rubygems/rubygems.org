# frozen_string_literal: true

class Version::ProvenanceComponentPreview < Lookbook::Preview
  def default
    render Version::ProvenanceComponent.new(
      attestation: FactoryBot.build(:attestation)
    )
  end

  def gitlab
    certificate = FactoryBot.build(:sigstore_x509_certificate,
      x509_certificate: FactoryBot.build(:x509_certificate, :key_usage, :gitlab_fulcio))
    bundle = FactoryBot.build(:sigstore_bundle,
      verification_material: FactoryBot.build(:sigstore_verification_material, certificate:))
    render Version::ProvenanceComponent.new(
      attestation: FactoryBot.build(:attestation, body: bundle)
    )
  end
end
