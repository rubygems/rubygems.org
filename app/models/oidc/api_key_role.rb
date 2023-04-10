class OIDC::ApiKeyRole < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider", foreign_key: "oidc_provider_id", inverse_of: :api_key_roles
  belongs_to :user

  has_many :id_tokens, class_name: "OIDC::IdToken", inverse_of: :api_key_role, foreign_key: :oidc_api_key_role_id, dependent: :nullify

  Dry::Schema.load_extensions(:hints)

  attribute :api_key_permissions, JsonDeserializable.new(OIDC::ApiKeyPermissions)
  validates :api_key_permissions, presence: true, nested: true
  validate :gems_belong_to_user

  def gems_belong_to_user
    Array.wrap(api_key_permissions.gems).each_with_index do |name, idx|
      errors.add("api_key_permissions.gems[#{idx}]", "(#{name}) does not belong to user #{user.display_handle}") if user.rubygems.where(name:).empty?
    end
  end

  attribute :access_policy, JsonDeserializable.new(OIDC::AccessPolicy)
  validates :access_policy, presence: true, nested: true
  validate :all_condition_claims_are_known

  def all_condition_claims_are_known
    known_claims = provider.configuration.claims_supported
    access_policy.statements.each_with_index do |s, si|
      s.conditions.each_with_index do |c, ci|
        unless known_claims.include?(c[:claim])
          errors.add("access_policy.statements[#{si}].conditions[#{ci}].claim",
                     "unknown claim for the provider")
        end
      end
    end
  end
end
