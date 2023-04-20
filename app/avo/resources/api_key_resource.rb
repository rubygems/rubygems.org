class ApiKeyResource < Avo::BaseResource
  self.title = :name
  self.includes = []

  field :id, as: :id, hide_on: :index

  field :name, as: :text, link_to_resource: true
  field :hashed_key, as: :text, visible: ->(_) { false }
  field :user, as: :belongs_to
  field :last_accessed_at, as: :date_time
  field :soft_deleted_at, as: :date_time
  field :soft_deleted_rubygem_name, as: :text
  field :expires_at, as: :date_time

  field :enabled_scopes, as: :tags

  sidebar do
    heading "Permissions"

    field :index_rubygems, as: :boolean
    field :push_rubygem, as: :boolean
    field :yank_rubygem, as: :boolean
    field :add_owner, as: :boolean
    field :remove_owner, as: :boolean
    field :access_webhooks, as: :boolean
    field :show_dashboard, as: :boolean
    field :mfa, as: :boolean
  end

  field :api_key_rubygem_scope, as: :has_one
  field :ownership, as: :has_one
  field :oidc_id_token, as: :has_one
end
