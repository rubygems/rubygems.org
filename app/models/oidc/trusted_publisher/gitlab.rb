# frozen_string_literal: true

class OIDC::TrustedPublisher::GitLab < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  validates :project_path, :ci_config_path,
    presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :environment, :branch_name, allow_nil: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :ref_type, inclusion: { in: %w[branch tag], allow_nil: true }, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }

  validates :project_path, uniqueness: { scope: %i[ci_config_path environment ref_type branch_name], message: :publisher_already_exists }
  validate :ci_config_path_format
  validate :branch_name_required_for_branch_ref_type

  def self.for_claims(claims)
    required = {
      project_path: claims.fetch(:project_path)
    }

    base = where(required)

    # Match environment
    base = if (env = claims[:environment])
             base.where(environment: env).or(base.where(environment: nil)).order(environment: :asc)
           else
             base.where(environment: nil)
           end

    # Match ref_type and branch_name
    # GitLab OIDC tokens provide ref_type (branch/tag), ref (short name e.g. main), and ref_path (full path e.g. refs/heads/main)
    if (ref_type = claims[:ref_type])
      if ref_type == "tag"
        base = base.where(ref_type: ["tag", nil])
      elsif ref_type == "branch"
        # ref claim is already the short branch name (e.g. "main"), not the full ref path
        branch = claims[:ref]
        base = base.where(ref_type: "branch", branch_name: branch)
          .or(base.where(ref_type: nil))
      end
    end

    base.first!
  end

  def self.permitted_attributes
    %i[project_path ci_config_path environment ref_type branch_name]
  end

  def self.build_trusted_publisher(params)
    attributes = params.slice(*permitted_attributes).transform_values(&:presence)
    attributes[:ci_config_path] ||= ".gitlab-ci.yml"
    find_or_initialize_by(attributes)
  end

  def self.publisher_name = "GitLab"

  def self.url_identifier = "gitlab"

  def self.form_component = OIDC::TrustedPublisher::GitLab::FormComponent

  def payload
    {
      name:,
      project_path:,
      ci_config_path:,
      environment:,
      ref_type:,
      branch_name:
    }
  end

  delegate :as_json, to: :payload

  def to_access_policy(jwt)
    common_conditions = [
      project_path_condition,
      environment_condition,
      audience_condition,
      *ref_conditions
    ].compact

    refs = [jwt[:ref_path], jwt[:sha]].compact_blank
    raise OIDC::AccessPolicy::AccessError, "ref and sha are both missing" if refs.empty?

    OIDC::AccessPolicy.new(
      statements: refs.map do |ref|
        OIDC::AccessPolicy::Statement.new(
          effect: "allow",
          principal: OIDC::AccessPolicy::Statement::Principal.new(
            oidc: OIDC::Provider::GITLAB_ISSUER
          ),
          conditions: common_conditions + [ci_config_ref_uri_condition(ref)]
        )
      end
    )
  end

  def name
    [
      "#{self.class.publisher_name} #{project_path} @ #{ci_config_path}",
      (environment? ? "(#{environment})" : nil),
      (ref_type? ? "[#{ref_type}]" : nil),
      (branch_name? ? "[#{branch_name}]" : nil)
    ].compact.join(" ")
  end

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  class UnsupportedSigstorePolicy
    def verify(_cert)
      Sigstore::VerificationFailure.new("Attestation verification is not supported for GitLab trusted publishers")
    end
  end

  def to_sigstore_identity_policy
    UnsupportedSigstorePolicy.new
  end

  private

  def project_path_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "project_path",
      value: project_path
    )
  end

  def environment_condition
    return if environment.blank?
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "environment",
      value: environment
    )
  end

  def audience_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "aud",
      value: Gemcutter::HOST
    )
  end

  def ci_config_ref_uri_condition(ref)
    # Use string_equals and strict matching because we know the structure
    # e.g. gitlab.com/group/project//.gitlab-ci.yml@refs/heads/main
    # Host is derived from the issuer (e.g. gitlab.com)
    # Project path and ci config path are from strict model attributes
    # Ref is from the token claim (full ref path)
    host = URI(OIDC::Provider::GITLAB_ISSUER).host

    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "ci_config_ref_uri",
      value: "#{host}/#{project_path}//#{ci_config_path}@#{ref}"
    )
  end

  # Returns an array of conditions that restrict the ref type and value.
  # For tags: enforces ref_type == "tag".
  # For branches: enforces both ref_type == "branch" and the specific branch ref.
  def ref_conditions
    return [] if ref_type.blank?

    if ref_type == "tag"
      [
        OIDC::AccessPolicy::Statement::Condition.new(
          operator: "string_equals",
          claim: "ref_type",
          value: "tag"
        )
      ]
    elsif ref_type == "branch" && branch_name.present?
      [
        OIDC::AccessPolicy::Statement::Condition.new(
          operator: "string_equals",
          claim: "ref_type",
          value: "branch"
        ),
        OIDC::AccessPolicy::Statement::Condition.new(
          operator: "string_equals",
          claim: "ref",
          value: "refs/heads/#{branch_name}"
        )
      ]
    else
      []
    end
  end

  def ci_config_path_format
    return if ci_config_path.blank?

    errors.add(:ci_config_path, :invalid_extension) unless /\.ya?ml\z/.match?(ci_config_path)
  end

  def branch_name_required_for_branch_ref_type
    return unless ref_type == "branch"
    return if branch_name.present?

    errors.add(:branch_name, "is required when ref_type is 'branch'")
  end
end
