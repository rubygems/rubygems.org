class OIDCRubygemTrustedPublisherResource < Avo::BaseResource
  self.title = :id
  self.includes = [:trusted_publisher]
  self.model_class = ::OIDC::RubygemTrustedPublisher

  field :id, as: :id
  # Fields generated from the model
  field :rubygem, as: :belongs_to
  field :trusted_publisher, as: :belongs_to, polymorphic_as: :trusted_publisher
  # add fields here
end
