class Avo::Resources::OIDCPendingTrustedPublisher < Avo::BaseResource
  self.includes = []
  self.model_class = ::OIDC::PendingTrustedPublisher

  class ExpiredFilter < Avo::Filters::ScopeBooleanFilter; end

  def filters
    filter ExpiredFilter, arguments: { default: { expired: false, unexpired: true } }
  end

  def fields
    field :id, as: :id

    field :rubygem_name, as: :text
    field :user, as: :belongs_to
    field :trusted_publisher, as: :belongs_to, polymorphic_as: :trusted_publisher
    field :expires_at, as: :date_time
  end
end
