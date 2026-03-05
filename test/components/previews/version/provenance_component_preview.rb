# frozen_string_literal: true

class Version::ProvenanceComponentPreview < Lookbook::Preview
  def default
    render Version::ProvenanceComponent.new(
      attestation: FactoryBot.build(:attestation)
    )
  end
end
