# frozen_string_literal: true

class OIDC::ApiKeyRole < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id", inverse_of: :api_key_roles
  belongs_to :user, inverse_of: :oidc_api_key_roles

  has_many :id_tokens, -> { order(created_at: :desc) },
    class_name: "OIDC::IdToken", inverse_of: :api_key_role, foreign_key: :oidc_api_key_role_id, dependent: :restrict_with_exception
  has_many :api_keys, through: :id_tokens, inverse_of: :oidc_api_key_role

  scope :for_rubygem, lambda { |rubygem|
    if rubygem.blank?
      where("(jsonb_typeof((#{arel_table.name}.api_key_permissions->'gems')::jsonb) = 'null' OR " \
            "jsonb_array_length((#{arel_table.name}.api_key_permissions->'gems')::jsonb) = 0)")
    else
      where("(#{arel_table.name}.api_key_permissions->'gems')::jsonb @> ?", %([#{rubygem.name.to_json}]))
    end
  }

  scope :for_scope, lambda { |scope|
    where("(#{arel_table.name}.api_key_permissions->'scopes')::jsonb @> ?", %([#{scope.to_json}]))
  }

  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :active, -> { where(deleted_at: nil) }

  validates :name, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, uniqueness: { scope: :user_id }

  attribute :api_key_permissions, Types::JsonDeserializable.new(OIDC::ApiKeyPermissions)
  validates :api_key_permissions, presence: true, nested: true
  validate :gems_belong_to_user

  def github_actions_push?
    provider.github_actions? && api_key_permissions.scopes.include?("push_rubygem")
  end

  # job_workflow_ref names the called reusable workflow, not the caller; a public
  # reusable workflow may be invoked from a different repository.
  GITHUB_ACTIONS_BINDING_CLAIMS = %w[
    repository repository_id repository_owner repository_owner_id
  ].freeze

  GITHUB_ACTIONS_SUBJECT_PREFIX = "repo:"

  BUILDKITE_BINDING_CLAIMS = %w[organization_id organization_slug pipeline_id].freeze

  def workload_binding_required?
    return false unless provider

    Array(api_key_permissions&.scopes).map(&:to_s).intersect?(
      (ApiKey::APPLICABLE_GEM_API_SCOPES + %i[access_webhooks access_oidc_api_key_roles show_dashboard]).map(&:to_s)
    )
  end

  def condition_binds_workload?(condition)
    return false unless condition.operator == "string_equals" && condition.value.present?

    if github_actions_issuer?
      if condition.claim == "sub"
        condition.value.to_s.start_with?(GITHUB_ACTIONS_SUBJECT_PREFIX)
      else
        GITHUB_ACTIONS_BINDING_CLAIMS.include?(condition.claim)
      end
    elsif buildkite_issuer?
      BUILDKITE_BINDING_CLAIMS.include?(condition.claim)
    else
      condition.claim == "sub"
    end
  end

  def github_actions_issuer?
    provider&.github_actions? || provider&.issuer&.end_with?(".token.actions.githubusercontent.com")
  end

  def buildkite_issuer?
    provider&.buildkite? || provider&.issuer&.end_with?(".agent.buildkite.com")
  end

  def access_policy_binds_workload?
    return true unless workload_binding_required?

    allow_statements = Array(access_policy&.statements).select { it.effect == "allow" }
    return false if allow_statements.empty?

    allow_statements.all? do |statement|
      Array(statement.conditions).any? { |condition| condition_binds_workload?(condition) }
    end
  end

  def verify_access!(jwt)
    unless access_policy_binds_workload?
      raise OIDC::AccessPolicy::AccessError,
        "refusing to issue an API key: access policy #{workload_binding_error}"
    end
    access_policy.verify_access!(jwt)
  end

  def gems_belong_to_user
    Array.wrap(api_key_permissions&.gems).each_with_index do |name, idx|
      errors.add("api_key_permissions.gems[#{idx}]", "(#{name}) does not belong to user #{user.display_handle}") if user.rubygems.where(name:).empty?
    end
  end

  # The admin panel records an Audit the owner cannot see, and api_key_created is
  # only mailed once a key has already been minted.
  after_update_commit :record_access_policy_change, if: :saved_change_to_access_policy?

  def record_access_policy_change
    by_owner = Current.user == user
    user.record_event!(
      Events::UserEvent::OIDC_API_KEY_ROLE_ACCESS_POLICY_CHANGED,
      # The event is the owner's to read, and show_additional_info? renders the
      # request's address and user agent to them. Withhold an admin's.
      request: by_owner ? Current.request : nil,
      name:,
      api_key_role_gid: to_global_id,
      by_owner:,
      conditions: Array.wrap(access_policy&.statements).flat_map do |statement|
        Array.wrap(statement.conditions).map { "#{it.claim} #{it.operator} #{it.value}" }
      end
    )
  end

  before_validation :set_statement_principals
  attribute :access_policy, Types::JsonDeserializable.new(OIDC::AccessPolicy)
  validates :access_policy, presence: true, nested: true
  validate :all_condition_claims_are_known
  validate :access_policy_binds_workload

  # Since the only current value of this is the provider's issuer, we can set it automatically.
  def set_statement_principals
    return unless provider
    access_policy&.statements&.each do |statement|
      statement.principal ||= OIDC::AccessPolicy::Statement::Principal.new
      next if statement.principal.oidc.present?
      statement.principal.oidc = provider.issuer
    end
  end

  def all_condition_claims_are_known
    return unless provider
    known_claims = provider.configuration.claims_supported
    access_policy.statements&.each_with_index do |s, si|
      s.conditions&.each_with_index do |c, ci|
        next if known_claims&.include?(c.claim)
        errors.add("access_policy.statements[#{si}].conditions[#{ci}].claim",
                   "unknown for the provider")
        c.errors.add(:claim,
                   "unknown for the provider")
      end
    end
  end

  def access_policy_binds_workload
    return if access_policy_binds_workload?

    errors.add(:access_policy, workload_binding_error)
  end

  def workload_binding_error
    if github_actions_issuer?
      "must bind the token to a repository for a GitHub Actions role with account access: " \
        "constrain one of #{GITHUB_ACTIONS_BINDING_CLAIMS.join(', ')}, or a `sub` pinned to a " \
        "repository (an exact `repo:...` subject). A policy that only checks `aud` - or only a " \
        "customized/pattern-matched `sub` - can be assumed by any repository on GitHub."
    elsif buildkite_issuer?
      "must bind the token to a specific workload for an OIDC role with account access: " \
        "constrain one of #{BUILDKITE_BINDING_CLAIMS.join(', ')}. A policy that only checks " \
        "`aud` or `build_branch` can be assumed by another Buildkite organization."
    else
      "must bind the token to a specific workload for an OIDC role with account access: " \
        "constrain an exact `sub` claim. A policy that only checks `aud` can be assumed by " \
        "any workload the provider issues a token to."
    end
  end

  # https://www.crockford.com/base32.html
  CROCKFORD_BASE_32_ALPHABET = ("0".."9").to_a + ("a".."z").to_a - %w[0 i l u]
  validates :token, presence: true, uniqueness: true, length: { minimum: 32, maximum: 32 },
    format: { with: /\Arg_oidc_akr_[#{CROCKFORD_BASE_32_ALPHABET}]+\z/o }

  before_validation :generate_random_token, if: :new_record?
  def generate_random_token
    5.times do
      suffix = SecureRandom.random_bytes(20).unpack("C*").map do |byte|
        idx = byte % 32
        CROCKFORD_BASE_32_ALPHABET[idx]
      end.join

      self.token = "rg_oidc_akr_#{suffix}"

      return if self.class.where(token:).empty?
    end

    raise "could not generate unique token"
  end
end
