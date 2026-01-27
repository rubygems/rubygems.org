class OIDC::TrustedPublisher::GitHubAction < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  before_validation :find_github_repository_owner_id

  validates :repository_owner, :repository_name, :workflow_filename, :repository_owner_id,
    presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :environment, allow_nil: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :workflow_repository_owner, :workflow_repository_name,
    allow_blank: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :workflow_repository_owner, presence: true, if: -> { workflow_repository_name.present? }
  validates :workflow_repository_name, presence: true, if: -> { workflow_repository_owner.present? }

  validate :unique_publisher
  validate :workflow_filename_format
  validate :workflow_repository_differs_from_repository

  def self.for_claims(claims)
    repository = claims.fetch(:repository)
    repository_owner, repository_name = repository.split("/", 2)
    job_workflow_ref = claims.fetch(:job_workflow_ref)

    match = job_workflow_ref.match(%r{\A([^/]+)/([^/]+)/\.github/workflows/([^@]+)@})
    raise ActiveRecord::RecordNotFound, "Invalid job_workflow_ref format" unless match

    workflow_repo_owner, workflow_repo_name, workflow_filename = match.captures

    required = {
      repository_owner:, repository_name:, workflow_filename:,
      repository_owner_id: claims.fetch(:repository_owner_id)
    }

    base = where(required)

    same_repo = workflow_repo_owner == repository_owner && workflow_repo_name == repository_name
    base = if same_repo
             base.where(workflow_repository_owner: nil, workflow_repository_name: nil)
           else
             base.where(workflow_repository_owner: workflow_repo_owner, workflow_repository_name: workflow_repo_name)
           end

    if (env = claims[:environment])
      base.where(environment: env).or(base.where(environment: nil)).order(environment: :asc) # NULLS LAST by default for asc
    else
      base.where(environment: nil)
    end.first!
  end

  def self.permitted_attributes
    %i[repository_owner repository_name workflow_filename environment
       workflow_repository_owner workflow_repository_name]
  end

  def self.build_trusted_publisher(params)
    params = params.reverse_merge(repository_owner_id: nil, repository_name: nil, workflow_filename: nil, environment: nil,
                                  workflow_repository_owner: nil, workflow_repository_name: nil)
    params.delete(:repository_owner_id)
    params[:environment] = nil if params[:environment].blank?
    params[:workflow_repository_owner] = nil if params[:workflow_repository_owner].blank?
    params[:workflow_repository_name] = nil if params[:workflow_repository_name].blank?
    find_or_initialize_by(params)
  end

  def self.publisher_name = "GitHub Actions"

  def payload
    {
      name:,
      repository_owner:,
      repository_name:,
      repository_owner_id:,
      workflow_filename:,
      environment:,
      workflow_repository_owner:,
      workflow_repository_name:
    }
  end

  delegate :as_json, to: :payload

  def repository_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "repository",
      value: [repository_owner, repository_name].join("/")
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

  def repository_owner_id_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "repository_owner_id",
      value: repository_owner_id
    )
  end

  def audience_condition
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "aud",
      value: Gemcutter::HOST
    )
  end

  def job_workflow_ref_condition(ref)
    OIDC::AccessPolicy::Statement::Condition.new(
      operator: "string_equals",
      claim: "job_workflow_ref",
      value: "#{workflow_repository}/#{workflow_slug}@#{ref}"
    )
  end

  def to_access_policy(jwt)
    common_conditions = [repository_condition, environment_condition, repository_owner_id_condition, audience_condition].compact
    refs = [jwt.fetch(:ref), jwt.fetch(:sha)].compact_blank
    raise OIDC::AccessPolicy::AccessError, "ref and sha are both missing" if refs.empty?
    OIDC::AccessPolicy.new(
      statements: refs.map do |ref|
        OIDC::AccessPolicy::Statement.new(
          effect: "allow",
          principal: OIDC::AccessPolicy::Statement::Principal.new(
            oidc: OIDC::Provider::GITHUB_ACTIONS_ISSUER
          ),
          conditions: common_conditions + [job_workflow_ref_condition(ref)]
        )
      end
    )
  end

  class SigstorePolicy
    def initialize(trusted_publisher)
      @trusted_publisher = trusted_publisher
    end

    def verify(cert)
      ref = cert.openssl.find_extension("1.3.6.1.4.1.57264.1.14")&.value_der&.then { OpenSSL::ASN1.decode(it).value }
      Sigstore::Policy::Identity.new(
        identity: "https://github.com/#{@trusted_publisher.workflow_repository}/#{@trusted_publisher.workflow_slug}@#{ref}",
        issuer: OIDC::Provider::GITHUB_ACTIONS_ISSUER
      ).verify(cert)
    end
  end

  def to_sigstore_identity_policy
    SigstorePolicy.new(self)
  end

  def name
    name = "#{self.class.publisher_name} #{repository_owner}/#{repository_name} @ #{workflow_slug}"
    name << " (#{environment})" if environment?
    name
  end

  def repository = "#{repository_owner}/#{repository_name}"

  def workflow_repository
    if workflow_repository_owner.present? && workflow_repository_name.present?
      "#{workflow_repository_owner}/#{workflow_repository_name}"
    else
      repository
    end
  end

  def workflow_slug = ".github/workflows/#{workflow_filename}"

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  private

  def find_github_repository_owner_id
    return if repository_owner.blank?
    return if repository_owner_id.present?

    self.repository_owner_id =
      begin
        Octokit::Client.new.user(repository_owner).id
      rescue Octokit::NotFound
        nil
      end
  end

  def unique_publisher
    return unless self.class.exists?(
      repository_owner: repository_owner,
      repository_name: repository_name,
      repository_owner_id: repository_owner_id,
      workflow_filename: workflow_filename,
      environment: environment,
      workflow_repository_owner: workflow_repository_owner,
      workflow_repository_name: workflow_repository_name
    )

    errors.add(:base, "publisher already exists")
  end

  def workflow_filename_format
    return if workflow_filename.blank?

    errors.add(:workflow_filename, "must end with .yml or .yaml") unless /\.ya?ml\z/.match?(workflow_filename)
    errors.add(:workflow_filename, "must be a filename only, without directories") if workflow_filename.include?("/")
  end

  def workflow_repository_differs_from_repository
    return if workflow_repository_owner.blank? && workflow_repository_name.blank?
    return unless workflow_repository_owner == repository_owner && workflow_repository_name == repository_name

    errors.add(:base, "workflow_repository must be different from the repository, leave blank for same-repository workflows")
  end
end
