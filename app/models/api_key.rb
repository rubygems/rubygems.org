class ApiKey < ApplicationRecord
  API_SCOPES = %i[index_rubygems push_rubygem yank_rubygem add_owner remove_owner access_webhooks show_dashboard].freeze

  belongs_to :user
  validates :user, :name, :hashed_key, presence: true
  validate :exclusive_show_dashboard_scope, if: :can_show_dashboard?
  validate :scope_presence
  validates :name, format: {
    with: /\A[a-zA-Z0-9_-]*\z/,
    message: "can only contain letters, numbers, dash and underscores"
  }, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }

  def enabled_scopes
    API_SCOPES.map { |scope| scope if send(scope) }.compact
  end

  API_SCOPES.each do |scope|
    define_method(:"can_#{scope}?") do
      scope_enabled = send(scope)
      return scope_enabled if !scope_enabled || new_record?
      touch :last_accessed_at
    end
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
end
