class WebauthnCredentialResource < Avo::BaseResource
  self.title = :id
  self.includes = []

  field :id, as: :id
  # Fields generated from the model
  field :external_id, as: :text
  field :public_key, as: :text
  field :nickname, as: :text
  field :sign_count, as: :number
  field :user, as: :belongs_to
  # add fields here
end
