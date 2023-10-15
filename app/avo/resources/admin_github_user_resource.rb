class AdminGitHubUserResource < Avo::BaseResource
  self.title = :login
  self.includes = []
  self.model_class = ::Admin::GitHubUser
  self.search_query = lambda {
    scope.where("login LIKE ?", "%#{params[:q]}%")
  }

  self.description = "GitHub users that have authenticated via the admin OAuth flow."

  field :id, as: :id

  field :is_admin, as: :boolean, readonly: true
  field :login, as: :text, readonly: true,
    as_html: true,
    format_using: -> { link_to value, "https://github.com/#{value}" }
  field :avatar_url, as: :external_image, name: "Avatar", readonly: true
  field :github_id, as: :text, readonly: true
  field :oauth_token, as: :text, visible: ->(resource:) { false } # rubocop:disable Lint/UnusedBlockArgument

  heading "Details"

  field :teams, as: :tags, readonly: true, format_using: -> { value.pluck(:slug) }

  field :info_data,
    as: :code, readonly: true, language: :javascript,
    format_using: -> { JSON.pretty_generate value }

  field :audits, as: :has_many
end
