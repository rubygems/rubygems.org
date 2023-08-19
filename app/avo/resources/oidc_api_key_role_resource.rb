class OIDCApiKeyRoleResource < Avo::BaseResource
  self.title = :token
  self.includes = []
  self.model_class = ::OIDC::ApiKeyRole
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :token, as: :text, link_to_resource: true, readonly: true
  field :id, as: :id, link_to_resource: true, hide_on: :index
  # Fields generated from the model
  field :name, as: :text
  field :provider, as: :belongs_to
  field :user, as: :belongs_to, searchable: true
  field :api_key_permissions, as: :nested do
    field :valid_for, as: :text, format_using: :iso8601
    field :scopes, as: :tags, suggestions: ApiKey::API_SCOPES.map { { label: _1, value: _1 } }, enforce_suggestions: true
    field :gems, as: :tags, suggestions: -> { Rubygem.limit(10).pluck(:name).map { { value: _1, label: _1 } } }
  end
  field :access_policy, as: :nested do
    field :statements, as: :array_of, field: :nested do
      field :effect, as: :select, options: { "Allow" => "allow" }, default: "Allow"
      field :principal, as: :nested, field_options: { stacked: false } do
        field :oidc, as: :text
      end
      field :conditions, as: :array_of, field: :nested, field_options: { stacked: false } do
        field :operator, as: :select, options: OIDC::AccessPolicy::Statement::Condition::OPERATORS.index_by(&:titleize)
        field :claim, as: :text
        field :value, as: :text
      end
    end
  end

  field :id_tokens, as: :has_many
  # add fields here
end
