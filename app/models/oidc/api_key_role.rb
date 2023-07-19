class OIDC::ApiKeyRole < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id", inverse_of: :api_key_roles
  belongs_to :user

  has_many :id_tokens, class_name: "OIDC::IdToken", inverse_of: :api_key_role, foreign_key: :oidc_api_key_role_id, dependent: :nullify

  attribute :api_key_permissions, Types::JsonDeserializable.new(OIDC::ApiKeyPermissions)
  validates :api_key_permissions, presence: true, nested: true
  validate :gems_belong_to_user

  def gems_belong_to_user
    Array.wrap(api_key_permissions&.gems).each_with_index do |name, idx|
      errors.add("api_key_permissions.gems[#{idx}]", "(#{name}) does not belong to user #{user.display_handle}") if user.rubygems.where(name:).empty?
    end
  end

  attribute :access_policy, Types::JsonDeserializable.new(OIDC::AccessPolicy)
  validates :access_policy, presence: true, nested: true
  validate :all_condition_claims_are_known

  def all_condition_claims_are_known
    return unless provider
    known_claims = provider.configuration.claims_supported
    access_policy.statements&.each_with_index do |s, si|
      s.conditions&.each_with_index do |c, ci|
        unless known_claims.include?(c.claim)
          errors.add("access_policy.statements[#{si}].conditions[#{ci}].claim",
                     "unknown claim for the provider")
          c.errors.add(:claim,
                     "unknown claim for the provider")
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
