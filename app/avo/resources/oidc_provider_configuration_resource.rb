class OIDCProviderConfigurationResource < Avo::BaseResource
  self.title = :to_s
  self.includes = []
  self.model_class = ::OIDC::Provider::Configuration
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  # Fields generated from the model
  field :issuer, as: :text
  field :jwks_uri, as: :text
  field :response_types_supported, as: :tags
  field :subject_types_supported, as: :tags
  field :id_token_signing_alg_values_supported, as: :tags
  field :token_endpoint, as: :text
  field :userinfo_endpoint, as: :text
  field :registration_endpoint, as: :text
  field :end_session_endpoint, as: :text
  field :service_documentation, as: :text
  field :check_session_iframe, as: :text
  field :op_policy_uri, as: :text
  field :op_tos_uri, as: :text
  field :scopes_supported, as: :tags
  field :response_modes_supported, as: :tags
  field :grant_types_supported, as: :tags
  field :acr_values_supported, as: :tags
  field :id_token_encryption_alg_values_supported, as: :tags
  field :id_token_encryption_enc_values_supported, as: :tags
  field :userinfo_signing_alg_values_supported, as: :tags
  field :userinfo_encryption_alg_values_supported, as: :tags
  field :userinfo_encryption_enc_values_supported, as: :tags
  field :request_object_signing_alg_values_supported, as: :tags
  field :request_object_encryption_alg_values_supported, as: :tags
  field :request_object_encryption_enc_values_supported, as: :tags
  field :token_endpoint_auth_methods_supported, as: :tags
  field :token_endpoint_auth_signing_alg_values_supported, as: :tags
  field :display_values_supported, as: :tags
  field :claim_types_supported, as: :tags
  field :claims_supported, as: :tags
  field :claims_locales_supported, as: :tags
  field :ui_locales_supported, as: :tags
  field :claims_parameter_supported, as: :tags
  field :request_parameter_supported, as: :tags
  field :request_uri_parameter_supported, as: :tags
  field :require_request_uri_registration, as: :text
  field :authorization_endpoint, as: :text
  # add fields here
end
