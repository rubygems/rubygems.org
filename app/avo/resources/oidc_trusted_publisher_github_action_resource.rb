class OIDCTrustedPublisherGitHubActionResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.model_class = ::OIDC::TrustedPublisher::GitHubAction

  field :id, as: :id
  # Fields generated from the model
  field :repository_owner, as: :text
  field :repository_name, as: :text
  field :repository_owner_id, as: :text
  field :workflow_filename, as: :text
  field :environment, as: :text
  # add fields here
  #
  field :rubygem_trusted_publishers, as: :has_many
  field :pending_trusted_publishers, as: :has_many
  field :rubygems, as: :has_many, through: :rubygem_trusted_publishers
  field :api_keys, as: :has_many, inverse_of: :owner
end
