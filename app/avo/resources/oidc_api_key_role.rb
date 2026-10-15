# frozen_string_literal: true

class Avo::Resources::OIDCApiKeyRole < Avo::BaseResource
  self.title = :token
  self.includes = %i[provider user]
  self.model_class = ::OIDC::ApiKeyRole

  def fields
    # `disabled` keeps a top level field out of the permitted params; `readonly`
    # would render it uneditable but still let a crafted request write it.
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
    field :access_policy, as: :nested, update_using: -> { Avo::Resources::OIDCApiKeyRole.merge_conditions(record, value) } do
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

  # Statements are matched by position, because the array field keeps the order
  # of the submitted indexes and not the indexes themselves. That only holds for
  # a form rendered against the policy being saved, so anything that does not
  # line up is rejected rather than ignored: otherwise a stale form writes its
  # conditions onto a statement the admin never looked at.
  def self.merge_conditions(record, submitted)
    access_policy = record.access_policy
    return access_policy if access_policy&.statements.blank?

    submitted_statements = Array.wrap(submitted.to_h.with_indifferent_access[:statements])
    if submitted_statements.size != access_policy.statements.size
      record.errors.add :access_policy, "may have changed since the form was opened; reload it and try again"
      return access_policy
    end

    statements = access_policy.statements.zip(submitted_statements).map do |statement, submitted_statement|
      unless same_statement?(statement, submitted_statement)
        record.errors.add :access_policy, "statements can only have their conditions changed"
        return access_policy
      end

      attributes = statement.as_json
      conditions = submitted_statement[:conditions]
      attributes["conditions"] = conditions unless conditions.nil?
      OIDC::AccessPolicy::Statement.new(attributes)
    end

    OIDC::AccessPolicy.new(statements:)
  end

  # Disabled inputs are not submitted, so these are normally absent. Anything
  # that does send them has to send them unchanged.
  def self.same_statement?(statement, submitted)
    return false if submitted.key?(:effect) && submitted[:effect] != statement.effect
    return false if submitted.key?(:principal) && submitted.dig(:principal, :oidc) != statement.principal&.oidc

    true
  end
end
