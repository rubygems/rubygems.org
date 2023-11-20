class OIDC::TrustedPublisher::GitHubAction < ApplicationRecord
  has_many :rubygem_trusted_publishers, class_name: "OIDC::RubygemTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", as: :trusted_publisher, dependent: :destroy,
    inverse_of: :trusted_publisher
  has_many :rubygems, through: :rubygem_trusted_publishers
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  before_validation :find_github_repository_owner_id

  validates :repository_owner, presence: true
  validates :repository_name, presence: true
  validates :workflow_filename, presence: true
  validates :environment, presence: true, allow_nil: true
  validates :repository_owner_id, presence: true

  validate :unique_publisher
  validate :workflow_filename_format

  def self.for_claims(claims)
    repository = claims.fetch(:repository)
    repository_owner, repository_name = repository.split("/", 2)
    workflow_prefix = "#{repository}/.github/workflows/"
    workflow_ref = claims.fetch(:job_workflow_ref).delete_prefix(workflow_prefix)
    workflow_filename = workflow_ref.sub(/@[^@]+\z/, "")

    required = {
      repository_owner:, repository_name:, workflow_filename:,
      repository_owner_id: claims.fetch(:repository_owner_id)
    }

    base = where(required)
    if (env = claims[:environment])
      base.where(environment: env).or(base.where(environment: nil)).order(environment: :asc) # NULLS LAST by default for asc
    else
      base.where(environment: nil)
    end.first!
  end

  def self.permitted_attributes
    %i[repository_owner repository_name workflow_filename environment]
  end

  def self.build_trusted_publisher(params)
    params.delete(:environment) if params[:environment].blank?
    params = params.reverse_merge(repository_owner_id: nil, repository_name: nil, workflow_filename: nil, environment: nil)
    find_or_initialize_by(params)
  end

  def self.publisher_name = "GitHub Actions"

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
      value: "#{repository}/#{workflow_slug}@#{ref}"
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

  def name
    name = "#{self.class.publisher_name} #{repository_owner}/#{repository_name} @ #{workflow_slug}"
    name << " (#{environment})" if environment?
    name
  end

  def repository = "#{repository_owner}/#{repository_name}"

  def workflow_slug = ".github/workflows/#{workflow_filename}"

  def owns_gem?(rubygem) = rubygem_trusted_publishers.exists?(rubygem: rubygem)

  def ld_context
    LaunchDarkly::LDContext.create(
      key: "#{model_name.singular}-key-#{id}",
      kind: "trusted_publisher",
      name: name
    )
  end

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
      environment: environment
    )

    errors.add(:base, "publisher already exists")
  end

  def workflow_filename_format
    return if workflow_filename.blank?

    errors.add(:workflow_filename, "must end with .yml or .yaml") unless /\.ya?ml\z/.match?(workflow_filename)
    errors.add(:workflow_filename, "must be a filename only, without directories") if workflow_filename.include?("/")
  end
end
