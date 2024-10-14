class Avo::Resources::ApiKey < Avo::BaseResource
  self.title = :name
  self.includes = []

  class ExpiredFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter ExpiredFilter, arguments: { default: { expired: false, unexpired: true } }
  end

  def fields
    main_panel do
      field :id, as: :id, hide_on: :index

      field :name, as: :text, link_to_resource: true
      field :hashed_key, as: :text, visible: -> { false }
      field :user, as: :belongs_to, visible: -> { false }
      field :owner, as: :belongs_to,
        polymorphic_as: :owner,
        types: [::User, ::OIDC::TrustedPublisher::GitHubAction]
      field :last_accessed_at, as: :date_time
      field :soft_deleted_at, as: :date_time
      field :soft_deleted_rubygem_name, as: :text
      field :expires_at, as: :date_time

      field :enabled_scopes, as: :tags

      sidebar do
        field :permissions, as: :heading

        field :index_rubygems, as: :boolean
        field :push_rubygem, as: :boolean
        field :yank_rubygem, as: :boolean
        field :add_owner, as: :boolean
        field :remove_owner, as: :boolean
        field :access_webhooks, as: :boolean
        field :show_dashboard, as: :boolean
        field :mfa, as: :boolean
      end
    end

    field :api_key_rubygem_scope, as: :has_one
    field :ownership, as: :has_one
    field :oidc_id_token, as: :has_one
  end
end
