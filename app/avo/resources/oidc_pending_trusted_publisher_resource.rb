class OIDCPendingTrustedPublisherResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  self.model_class = ::OIDC::PendingTrustedPublisher

  class ExpiredFilter < ScopeBooleanFilter; end
  filter ExpiredFilter, arguments: { default: { expired: false, unexpired: true } }

  field :id, as: :id
  # Fields generated from the model
  field :rubygem_name, as: :text
  field :user, as: :belongs_to
  field :trusted_publisher, as: :belongs_to, polymorphic_as: :trusted_publisher
  field :expires_at, as: :date_time
  # add fields here
end
