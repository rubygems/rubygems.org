class Avo::Resources::OIDCTrustedPublisherGitHubAction < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.model_class = ::OIDC::TrustedPublisher::GitHubAction

  def fields
    field :id, as: :id

    field :repository_owner, as: :text
    field :repository_name, as: :text
    field :repository_owner_id, as: :text
    field :workflow_filename, as: :text
    field :environment, as: :text

    field :rubygem_trusted_publishers, as: :has_many
    field :pending_trusted_publishers, as: :has_many
    field :rubygems, as: :has_many, through: :rubygem_trusted_publishers
    field :api_keys, as: :has_many, inverse_of: :owner
  end
end
