class ApiKey < ApplicationRecord
  class ScopeError < RuntimeError; end

  API_SCOPES = %i[show_dashboard index_rubygems push_rubygem yank_rubygem add_owner update_owner remove_owner access_webhooks
                  configure_trusted_publishers].freeze
  APPLICABLE_GEM_API_SCOPES = %i[push_rubygem yank_rubygem add_owner update_owner remove_owner configure_trusted_publishers].freeze
  EXCLUSIVE_SCOPES = %i[show_dashboard].freeze

  self.ignored_columns += API_SCOPES

  belongs_to :owner, polymorphic: true

  has_one :api_key_rubygem_scope, dependent: :destroy
  has_one :ownership, through: :api_key_rubygem_scope
  has_one :oidc_id_token, class_name: "OIDC::IdToken", dependent: :restrict_with_error
  has_one :oidc_api_key_role, class_name: "OIDC::ApiKeyRole", through: :oidc_id_token, source: :api_key_role, inverse_of: :api_keys
  has_many :pushed_versions, class_name: "Version", inverse_of: :pusher_api_key, foreign_key: :pusher_api_key_id, dependent: :nullify

  before_validation :set_owner_from_user
  after_create :record_create_event
  after_update :record_expire_event, if: :saved_change_to_expires_at?

  validate :exclusive_show_dashboard_scope, if: :can_show_dashboard?
  validate :scope_presence
  validates :name, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validates :hashed_key, presence: true, uniqueness: true
  validates :expires_at, inclusion: { in: -> { 1.minute.from_now.. } }, allow_nil: true, on: :create
  validate :rubygem_scope_definition, if: :ownership
  validate :known_scopes
  validate :not_soft_deleted?
  validate :not_expired?

  delegate :rubygem_id, :rubygem, to: :ownership, allow_nil: true

  scope :unexpired, -> { where(arel_table[:expires_at].eq(nil).or(arel_table[:expires_at].gt(Time.now.utc))) }
  scope :expired, -> { where(arel_table[:expires_at].lteq(Time.now.utc)) }

  scope :oidc, -> { joins(:oidc_id_token) }
  scope :not_oidc, -> { where.missing(:oidc_id_token) }

  def self.expire_all!
    transaction do
      unexpired.find_each.all?(&:expire!)
    end
  end

  def scope?(scope, scoped_gem = nil)
    scope_enabled = scopes.include?(scope)
    # TODO: once all calls to scope checks are changed, this check should
    # fail if the api_key has a rubygem but scope? is called without a scoped_gem
    scope_enabled = false if scoped_gem && rubygem_id && rubygem_id != scoped_gem.id
    return scope_enabled if !scope_enabled || new_record?
    touch :last_accessed_at
  end

  API_SCOPES.each do |scope|
    define_method(:"can_#{scope}?") { scope?(scope) }
    alias_method scope, :"can_#{scope}?"
  end

  def scopes
    super&.map(&:to_sym) || []
  end

  def user
    owner if user?
  end

  def user?
    owner_type == "User"
  end

  def trusted_publisher?
    owner_type.deconstantize == "OIDC::TrustedPublisher"
  end

  delegate :mfa_required_not_yet_enabled?, :mfa_required_weak_level_enabled?,
    :mfa_recommended_not_yet_enabled?, :mfa_recommended_weak_level_enabled?,
    to: :user, allow_nil: true

  def mfa_authorized?(otp)
    return true unless mfa_enabled?
    return true if oidc_id_token.present?
    user.api_mfa_verified?(otp)
  end

  def mfa_enabled?
    return false unless user?
    return false unless user.mfa_enabled?
    return false if short_lived?
    user.mfa_ui_and_api? || mfa
  end

  def short_lived?
    return false unless created_at && expires_at
    (expires_at - created_at) < 15.minutes
  end

  def rubygem_id=(id)
    self.ownership = id.blank? ? nil : user.ownerships.find_by!(rubygem_id: id)
  rescue ActiveRecord::RecordNotFound
    errors.add :rubygem, "must be a gem that you are an owner of"
  end

  def rubygem_name=(name)
    self.rubygem_id = name.blank? ? nil : Rubygem.find_by_name!(name).id
  rescue ActiveRecord::RecordNotFound
    errors.add :rubygem, "could not be found"
  end

  def soft_delete!(ownership: nil)
    update_attribute(:soft_deleted_at, Time.now.utc)
    update_attribute(:soft_deleted_rubygem_name, ownership.rubygem.name) if ownership
  end

  def soft_deleted?
    soft_deleted_at?
  end

  def soft_deleted_by_ownership?
    soft_deleted? && soft_deleted_rubygem_name.present?
  end

  def expired?
    expires_at && expires_at <= Time.now.utc
  end

  def expire!
    transaction do
      update_column(:expires_at, Time.current)
      record_expire_event
    end
  end

  private

  def exclusive_show_dashboard_scope
    errors.add :show_dashboard, "scope must be enabled exclusively" if other_enabled_scopes?
  end

  def other_enabled_scopes?
    scopes.-(%i[show_dashboard]).any?
  end

  def scope_presence
    errors.add :base, "Please enable at least one scope" if scopes.blank?
  end

  def rubygem_scope_definition
    return if APPLICABLE_GEM_API_SCOPES.intersect?(scopes)
    errors.add :rubygem, "scope can only be set for push/yank rubygem, and add/remove owner scopes"
  end

  def known_scopes
    errors.add :scopes, "scopes must be from #{API_SCOPES}, got: #{scopes}" if (scopes - API_SCOPES).present?
  end

  def not_soft_deleted?
    errors.add :base, "An invalid API key cannot be used. Please delete it and create a new one." if soft_deleted?
  end

  def not_expired?
    return false if changed == %w[expires_at]
    errors.add :base, "An expired API key cannot be used. Please create a new one." if expired?
  end

  def set_owner_from_user
    self.owner ||= user
  end

  def record_create_event
    case owner
    when User
      user.record_event!(Events::UserEvent::API_KEY_CREATED,
          name:, scopes:, gem: rubygem&.name, mfa:, api_key_gid: to_gid)
    end
  end

  def record_expire_event
    case owner
    when User
      user.record_event!(Events::UserEvent::API_KEY_DELETED,
          name:, api_key_gid: to_gid)
    end
  end
end
