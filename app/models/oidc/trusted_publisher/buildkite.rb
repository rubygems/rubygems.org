class OIDC::TrustedPublisher::Buildkite < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  validates :organization_slug, :pipeline_slug,
    presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }

  validate :unique_publisher

  def self.for_claims(claims)
    organization_slug = claims.fetch(:organization_slug)
    pipeline_slug = claims.fetch(:pipeline_slug)

    where(organization_slug:, pipeline_slug:).first!
  end

  def self.permitted_attributes
    %i[organization_slug pipeline_slug]
  end

  def self.build_trusted_publisher(params)
    params = params.reverse_merge(organization_slug: nil, pipeline_slug: nil)
    find_or_initialize_by(params)
  end

  def self.publisher_name = "Buildkite"

  def payload
    {
      name:,
      organization_slug:,
      pipeline_slug:
    }
  end

  delegate :as_json, to: :payload

  def organization_slug_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "organization_slug",
      value: organization_slug
    )
  end

  def pipeline_slug_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "pipeline_slug",
      value: pipeline_slug
    )
  end

  def audience_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "aud",
      value: Gemcutter::HOST
    )
  end

  def to_access_policy(jwt)
    # TODO what to do with jwt here?
    # TODO should we be checking the audience claim?
    common_conditions = [organization_slug_condition, pipeline_slug_condition].compact
    OIDC::AccessPolicy.new(
      statements: [
        OIDC::AccessPolicy::Statement.new(
          effect: "allow",
          principal: OIDC::AccessPolicy::Statement::Principal.new(
            oidc: OIDC::Provider::BUILDKITE_ISSUER
          ),
          conditions: common_conditions
        )
      ]
    )
  end

  #class SigstorePolicy
  #  def initialize(trusted_publisher)
  #    @trusted_publisher = trusted_publisher
  #  end

  #  def verify(cert)
  #    # 1.3.6.1.4.1.57264.1.14 is `Source Repository Ref` - AKA Branch or Tag
  #    ref = cert.openssl.find_extension("1.3.6.1.4.1.57264.1.14")&.value_der&.then { OpenSSL::ASN1.decode(_1).value }
  #    Sigstore::Policy::Identity.new(
  #      identity: "https://github.com/#{@trusted_publisher.repository}/#{@trusted_publisher.workflow_slug}@#{ref}",
  #      issuer: OIDC::Provider::BUILDKITE_ISSUER
  #    ).verify(cert)
  #  end
  #end

  #def to_sigstore_identity_policy
  #  SigstorePolicy.new(self)
  #end

  def name
    "#{self.class.publisher_name} #{organization_slug}/#{pipeline_slug}"
  end

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  def ld_context
    LaunchDarkly::LDContext.create(
      key: "#{model_name.singular}-key-#{id}",
      kind: "trusted_publisher",
      name: name
    )
  end

  private

  def unique_publisher
    return unless self.class.exists?(
      organization_slug: organization_slug,
      pipeline_slug: pipeline_slug,
    )

    errors.add(:base, "publisher already exists")
  end

end
