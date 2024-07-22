class OIDCIdTokenResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::IdToken
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :api_key_role, as: :belongs_to
  field :provider, as: :has_one
  field :api_key, as: :has_one

  heading "JWT"
  field :claims, as: :key_value, stacked: true do
    model.jwt.fetch("claims")
  end
  field :header, as: :key_value, stacked: true do
    model.jwt.fetch("header")
  end
  # add fields here
end
