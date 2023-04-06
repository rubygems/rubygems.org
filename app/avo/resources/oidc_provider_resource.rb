class OIDCProviderResource < Avo::BaseResource
  self.title = :issuer
  self.includes = []
  self.model_class = ::OIDC::Provider
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  action RefreshOIDCProvider

  # Fields generated from the model
  field :issuer, as: :text
  field :configuration, as: :json_viewer, hide_on: :index
  # field :configuration, as: :model_attribute, use_resource: OIDCProviderConfigurationResource, readonly: false, show_on: :edit
  field :jwks, as: :json_viewer, hide_on: :index
  field :api_key_roles, as: :has_many
  # add fields here
  field :id, as: :id
end
