class Avo::Resources::WebauthnCredential < Avo::BaseResource
  self.includes = []

  def fields
    field :id, as: :id

    field :external_id, as: :text
    field :public_key, as: :text
    field :nickname, as: :text
    field :sign_count, as: :number
    field :user, as: :belongs_to
  end
end
