class AdminGitHubUserResource < Avo::BaseResource
  self.title = :login
  self.includes = []
  self.model_class = ::Admin::GitHubUser
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  self.description = "GitHub users that have authenticated via the admin OAuth flow."

  field :id, as: :id

  field :is_admin, as: :boolean, readonly: true
  field :login, as: :text, readonly: true,
    as_html: true,
    format_using: -> (value) { link_to value, "https://github.com/#{value}"}
  field :avatar_url, as: :external_image, name: 'Avatar', readonly: true
  field :github_id, as: :text, readonly: true
  field :oauth_token, as: :text, visible: -> (resource:) { false }

  heading "Details"

  field :teams, as: :tags, readonly: true, format_using: ->(teams) { teams.map { _1[:slug] } }

  field :info_data,
    as: :code, readonly: true, language: :javascript,
    format_using: -> (info_data) { JSON.pretty_generate info_data}
end
