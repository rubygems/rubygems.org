class OIDC::TrustedPublisher::GitLab < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  validates :project_path, :ref_path, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :environment, :ci_config_ref_uri, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, allow_blank: true
  validate :unique_publisher

  def self.for_claims(claims)
    required = {
      project_path: claims.fetch(:project_path),
      ref_path: claims.fetch(:ref_path)
    }
    optional = {
      environment: claims.fetch(:environment, nil),
      ci_config_ref_uri: claims.fetch(:ci_config_ref_uri, nil)
    }.compact
    where(required.merge(optional)).first!
  end

  def self.permitted_attributes
    %i[project_path ref_path environment ci_config_ref_uri]
  end

  def self.build_trusted_publisher(params)
    params = params.reverse_merge(project_path: nil, ref_path: nil, environment: nil, ci_config_ref_uri: nil)
    find_or_initialize_by(params)
  end

  def self.publisher_name
    "GitLab"
  end

  def self.url_identifier = "gitlab"

  def self.form_component = OIDC::TrustedPublisher::GitLab::FormComponent

  def payload
    {
      name:,
      project_path:,
      ref_path:,
      environment:,
      ci_config_ref_uri:
    }
  end

  delegate :as_json, to: :payload

  def to_access_policy(_jwt)
    OIDC::AccessPolicy.new(
      statements: [
        OIDC::AccessPolicy::Statement.new(
          effect: "allow",
          principal: OIDC::AccessPolicy::Statement::Principal.new(
            oidc: OIDC::Provider::GITLAB_ISSUER
          ),
          conditions: [
            OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "project_path",
              value: project_path
            ),
            OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "ref_path",
              value: ref_path
            ),
            environment.present? && OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "environment",
              value: environment
            ),
            ci_config_ref_uri.present? && OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "ci_config_ref_uri",
              value: ci_config_ref_uri
            )
          ].compact.uniq
        )
      ]
    )
  end

  def name
    "#{self.class.publisher_name} #{project_path}"
  end

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  private

  def unique_publisher
    return unless self.class.exists?(
      project_path: project_path,
      ref_path: ref_path,
      environment: environment,
      ci_config_ref_uri: ci_config_ref_uri
    )

    errors.add(:base, "publisher already exists")
  end
end
