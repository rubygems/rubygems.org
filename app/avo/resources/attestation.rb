class Avo::Resources::Attestation < Avo::BaseResource
  self.title = :id
  self.includes = [:version]

  def actions
    action Avo::Actions::RepairAttestation
  end

  def fields
    field :id, as: :id

    field :valid, as: :boolean, only_on: %i[index show] do
      Rails.cache.fetch(["attestation-valid-bundle", record.id, record.updated_at]) do
        record.valid_bundle?
      end
    end

    field :version, as: :belongs_to
    field :media_type, as: :text
    field :body, as: :json_viewer

    field :leaf_certificate, as: :code, only_on: :show do
      record.sigstore_bundle.leaf_certificate.to_text
    end

    field :display_data, as: :json_viewer, only_on: :show do
      record.display_data
    end
  end
end
