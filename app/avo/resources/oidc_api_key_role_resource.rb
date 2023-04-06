class OIDCApiKeyRoleResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::ApiKeyRole
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  # field :oidc_provider, as: :belongs_to
  field :user, as: :belongs_to
  field :api_key_permissions, as: :text
  field :name, as: :text
  field :access_policy, as: :text
  # add fields here
end
