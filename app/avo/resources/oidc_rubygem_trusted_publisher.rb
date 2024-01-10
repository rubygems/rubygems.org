class Avo::Resources::OIDCRubygemTrustedPublisher < Avo::BaseResource
  self.title = :id
  self.includes = [:trusted_publisher]
  self.model_class = ::OIDC::RubygemTrustedPublisher

  def fields
    field :id, as: :id

    field :rubygem, as: :belongs_to
    field :trusted_publisher, as: :belongs_to, polymorphic_as: :trusted_publisher
  end
end
