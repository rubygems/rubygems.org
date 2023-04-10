class ApiKey < ApplicationRecord
  API_SCOPES = %i[index_rubygems push_rubygem yank_rubygem add_owner remove_owner access_webhooks show_dashboard].freeze
  APPLICABLE_GEM_API_SCOPES = %i[push_rubygem yank_rubygem add_owner remove_owner].freeze

  belongs_to :user
  has_one :api_key_rubygem_scope, dependent: :destroy
  has_one :ownership, through: :api_key_rubygem_scope
  has_one :oidc_id_token, class_name: "OIDC::IdToken"
  validates :user, :name, :hashed_key, presence: true
  validate :exclusive_show_dashboard_scope, if: :can_show_dashboard?
  validate :scope_presence
  validates :name, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :rubygem_scope_definition, if: :ownership
  validate :not_soft_deleted?
  validate :not_expired?

  delegate :rubygem_id, :rubygem, to: :ownership, allow_nil: true

  scope :unexpired, -> { where(arel_table[:expires_at].gteq(Time.now.utc)) }
  scope :expired, -> { where(arel_table[:expires_at].lt(Time.now.utc)) }

  def enabled_scopes
    API_SCOPES.filter_map { |scope| scope if send(scope) }
  end

  API_SCOPES.each do |scope|
    define_method(:"can_#{scope}?") do
      scope_enabled = send(scope)
      return scope_enabled if !scope_enabled || new_record?
      touch :last_accessed_at
    end
  end

  def mfa_authorized?(otp)
    return true unless mfa_enabled?
    user.api_mfa_verified?(otp)
  end

  def mfa_enabled?
    return false unless user.mfa_enabled?
    user.mfa_ui_and_api? || mfa
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
    expires_at && expires_at < Time.now.utc
  end

  private

  def exclusive_show_dashboard_scope
    errors.add :show_dashboard, "scope must be enabled exclusively" if other_enabled_scopes?
  end

  def other_enabled_scopes?
    enabled_scopes.tap { |scope| scope.delete(:show_dashboard) }.any?
  end

  def scope_presence
    errors.add :base, "Please enable at least one scope" unless enabled_scopes.any?
  end

  def rubygem_scope_definition
    return if APPLICABLE_GEM_API_SCOPES.intersect?(enabled_scopes)
    errors.add :rubygem, "scope can only be set for push/yank rubygem, and add/remove owner scopes"
  end

  def not_soft_deleted?
    errors.add :base, "An invalid API key cannot be used. Please delete it and create a new one." if soft_deleted?
  end

  def not_expired?
    errors.add :base, "An expired API key (#{expires_at}) cannot be used. Please create a new one." if expired?
  end
end
