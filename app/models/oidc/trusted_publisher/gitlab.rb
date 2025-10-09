class OIDC::TrustedPublisher::GitLab < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  validates :project_path, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :environment, :ci_config_ref_uri, :ref_path, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, allow_blank: true
  validate :unique_publisher
  validate :ci_config_ref_uri_format

  def self.for_claims(claims)
    required = {
      project_path: claims.fetch(:project_path)
    }
    base = where(required)

    if (env = claims[:environment])
      base.where(environment: env).or(base.where(environment: nil)).order(environment: :asc)
    else
      base.where(environment: nil)
    end.first!
  end

  def self.permitted_attributes
    %i[project_path ref_path environment ci_config_ref_uri]
  end

  def self.build_trusted_publisher(params)
    mapped_params = {
      project_path: params[:project_path],
      ci_config_ref_uri: params[:ci_config_ref_uri],
      environment: params[:environment],
      ref_path: params[:ref_path]
    }
    mapped_params[:environment] = nil if mapped_params[:environment].blank?
    find_or_initialize_by(mapped_params)
  end

  def self.publisher_name = "GitLab"

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
    conditions = [
      OIDC::AccessPolicy::Statement::Condition.new(
        operator: "string_equals",
        claim: "project_path",
        value: project_path
      ),
      OIDC::AccessPolicy::Statement::Condition.new(
        operator: "string_equals",
        claim: "aud",
        # value: Gemcutter::HOST
        value: "http://host.docker.internal:3000"
      )
    ]
    if environment.present?
      conditions << OIDC::AccessPolicy::Statement::Condition.new(
        operator: "string_equals",
        claim: "environment",
        value: environment
      )
    end

    OIDC::AccessPolicy.new(
      statements: [
        OIDC::AccessPolicy::Statement.new(
          effect: "allow",
          principal: OIDC::AccessPolicy::Statement::Principal.new(
            oidc: OIDC::Provider::GITLAB_ISSUER
          ),
          conditions: conditions
        )
      ]
    )
  end

  def name
    name = "#{self.class.publisher_name} #{project_path} @ #{ci_config_ref_uri}"
    name << " (#{environment})" if environment?
    name
  end

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  private

  def unique_publisher
    return unless self.class.exists?(
      project_path: project_path,
      ci_config_ref_uri: ci_config_ref_uri,
      environment: environment
    )

    errors.add(:base, "publisher already exists")
  end

  def ci_config_ref_uri_format
    return if ci_config_ref_uri.blank?

    errors.add(:ci_config_ref_uri, "must end with .yml or .yaml") unless /\.ya?ml\z/.match?(ci_config_ref_uri)
    errors.add(:ci_config_ref_uri, "must be a filename only, without directories") if ci_config_ref_uri.include?("/")
  end
end
