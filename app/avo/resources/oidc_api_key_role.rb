# frozen_string_literal: true

class Avo::Resources::OIDCApiKeyRole < Avo::BaseResource
  self.title = :token
  self.includes = %i[provider user]
  self.model_class = ::OIDC::ApiKeyRole

  def fields
    # Admins can only change the conditions of the access policy statements.
    # Everything else is disabled, which renders it disabled on the edit form
    # and leaves it out of the permitted params on update.
    field :token, as: :text, link_to_resource: true, disabled: true
    field :id, as: :id, link_to_resource: true, hide_on: :index, disabled: true
    # Fields generated from the model
    field :name, as: :text, disabled: true
    field :provider, as: :belongs_to, disabled: true
    field :user, as: :belongs_to, searchable: true, disabled: true
    field :api_key_permissions, as: :nested, disabled: true do
      field :valid_for, as: :text, format_using: -> { value&.iso8601 }, disabled: true
      field :scopes, as: :tags, suggestions: ApiKey::API_SCOPES.map { { label: it, value: it } }, enforce_suggestions: true, disabled: true
      field :gems, as: :tags, suggestions: -> { Rubygem.limit(10).pluck(:name).map { { value: it, label: it } } }, disabled: true
    end
    field :access_policy, as: :nested, update_using: -> { Avo::Resources::OIDCApiKeyRole.merge_conditions(record.access_policy, value) } do
      # The statements are fixed: none can be added or removed, and the effect
      # and principal of each one stay as they are. Only the conditions change.
      field :statements, as: :array_of, field: :nested, readonly: true do
        field :effect, as: :select, options: { "Allow" => "allow" }, default: "Allow", disabled: true
        field :principal, as: :nested, field_options: { stacked: false } do
          field :oidc, as: :text, disabled: true
        end
        field :conditions, as: :array_of, field: :nested, field_options: { stacked: false } do
          field :operator, as: :select, options: OIDC::AccessPolicy::Statement::Condition::OPERATORS.index_by(&:titleize)
          field :claim, as: :text
          field :value, as: :text
        end
      end
    end

    field :id_tokens, as: :has_many
  end

  # Builds the access policy to save from the persisted one and the submitted
  # form value. Each persisted statement keeps its effect and principal and gets
  # the conditions submitted for it; a statement nothing was submitted for is
  # kept as it is, and any statements submitted beyond the persisted ones are
  # ignored. Anything else in the submitted value is ignored too.
  def self.merge_conditions(access_policy, submitted)
    return access_policy if access_policy&.statements.blank?

    submitted_statements = Array.wrap(submitted.to_h.with_indifferent_access[:statements])
    statements = access_policy.statements.each_with_index.map do |statement, index|
      attributes = statement.as_json
      conditions = submitted_statements[index]&.dig(:conditions)
      attributes["conditions"] = conditions unless conditions.nil?
      OIDC::AccessPolicy::Statement.new(attributes)
    end

    OIDC::AccessPolicy.new(statements:)
  end
end
