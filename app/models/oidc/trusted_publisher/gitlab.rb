class OIDC::TrustedPublisher::GitLab < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  validates :namespace_path, :project_path, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :unique_publisher

  def self.for_claims(claims)
    required = {
      namespace_path: claims.fetch(:namespace_path),
      project_path: claims.fetch(:project_path)
    }

    where(required).first!
  end

  def self.permitted_attributes
    %i[namespace_path project_path]
  end

  def self.build_trusted_publisher(params)
    params = params.reverse_merge(namespace_path: nil, project_path: nil)
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
      namespace_path:,
      project_path:
    }
  end

  delegate :as_json, to: :payload

  def to_access_policy(jwt)
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
              claim: "namespace_path",
              value: namespace_path
            ),
            OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "project_path",
              value: project_path
            ),
            OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "ref",
              value: jwt.fetch(:ref)
            ),
            OIDC::AccessPolicy::Statement::Condition.new(
              operator: "string_equals",
              claim: "ref_type",
              value: jwt.fetch(:ref_type)
            )
          ].compact
        )
      ]
    )
  end

  def name
    "#{self.class.publisher_name} #{namespace_path}/#{project_path}"
  end

  private

  def unique_publisher
    return unless self.class.exists?(
      namespace_path: namespace_path,
      project_path: project_path
    )

    errors.add(:base, "publisher already exists")
  end
end
