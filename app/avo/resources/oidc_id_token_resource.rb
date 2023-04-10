class OIDCIdTokenResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::IdToken
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :oidc_api_key_role, as: :belongs_to
  field :jwt, as: :text
  field :oidc_provider, as: :belongs_to
  # add fields here
end
