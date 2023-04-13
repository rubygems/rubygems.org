class OIDCApiKeyRoleResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::ApiKeyRole
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id, link_to_resource: true
  # Fields generated from the model
  field :provider, as: :belongs_to
  field :user, as: :belongs_to
  field :api_key_permissions, as: :nested,
    coercer: ->(v) { OIDC::ApiKeyPermissions.new OIDC::ApiKeyPermissions::Contract.new.call(v).to_h } do
    field :valid_for, as: :text
    field :scopes, as: :tags, suggestions: ApiKey::API_SCOPES.map { { label: _1, value: _1 } }
    field :gems, as: :tags, suggestions: -> { Rubygem.limit(10).pluck(:name).map { { value: _1, label: _1 } } }
  end
  field :name, as: :text
  field :access_policy, as: :nested,
  coercer: ->(v) { OIDC::AccessPolicy.new OIDC::AccessPolicy::Contract.new.call(v).to_h } do
    field :statements, as: :array_of, field: :nested do
      field :effect, as: :select, options: { "Allow" => "allow" }, default: "Allow"
      field :principal, as: :nested, field_options: { stacked: false } do
        field :oidc, as: :text
      end
      field :conditions, as: :array_of, field: :nested, field_options: { stacked: false } do
        field :operator, as: :select, options: %w[string_equals].index_by(&:titleize)
        field :claim, as: :text
        field :value, as: :text
      end
    end
  end
  # add fields here
end
