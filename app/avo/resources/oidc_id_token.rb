class Avo::Resources::OIDCIdToken < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::IdToken

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :api_key_role, as: :belongs_to
    field :provider, as: :has_one
    field :api_key, as: :has_one

    field :jwt, as: :heading
    field :claims, as: :key_value, stacked: true do
      record.jwt.fetch("claims")
    end
    field :header, as: :key_value, stacked: true do
      record.jwt.fetch("header")
    end
  end
end
