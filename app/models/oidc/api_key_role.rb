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

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :user_id }

  attribute :api_key_permissions, Types::JsonDeserializable.new(OIDC::ApiKeyPermissions)
  validates :api_key_permissions, presence: true, nested: true
  validate :gems_belong_to_user

  def github_actions_push?
    provider.github_actions? && api_key_permissions.scopes.include?("push_rubygem")
  end

  def gems_belong_to_user
    Array.wrap(api_key_permissions&.gems).each_with_index do |name, idx|
      errors.add("api_key_permissions.gems[#{idx}]", "(#{name}) does not belong to user #{user.display_handle}") if user.rubygems.where(name:).empty?
    end
  end

  before_validation :set_statement_principals
  attribute :access_policy, Types::JsonDeserializable.new(OIDC::AccessPolicy)
  validates :access_policy, presence: true, nested: true
  validate :all_condition_claims_are_known

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
        unless known_claims&.include?(c.claim)
          errors.add("access_policy.statements[#{si}].conditions[#{ci}].claim",
                     "unknown for the provider")
          c.errors.add(:claim,
                     "unknown for the provider")
        end
      end
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
