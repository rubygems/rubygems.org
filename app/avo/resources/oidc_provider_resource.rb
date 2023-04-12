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
  field :configuration, as: :nested do
    field :claims_supported, as: :tags
    OpenIDConnect::Discovery::Provider::Config::Response.then { (_1.required_attributes + _1.optional_attributes) - fields.map(&:id) }.each do |k|
      field k, as: :text, visible: ->(_) { value.send(k).present? }
    end
  end
  field :jwks, as: :array_of, field: :json_viewer
  field :api_key_roles, as: :has_many
  # add fields here
  field :id, as: :id
end
