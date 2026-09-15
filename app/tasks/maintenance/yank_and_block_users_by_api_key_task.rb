# frozen_string_literal: true

class Maintenance::YankAndBlockUsersByApiKeyTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  attribute :api_key_name, :string
  attribute :created_within_hours, :integer, default: 24
  attribute :min_user_id, :integer
  attribute :max_user_id, :integer

  validates :api_key_name, presence: true
  validates :created_within_hours,
    numericality: { only_integer: true, greater_than: 0 }
  validate :max_user_id_not_before_min

  def collection
    scope = User.kept.where(blocked_email: nil)
      .where(id: matching_api_keys.select(:owner_id))
    scope = scope.where(id: min_user_id..) if min_user_id.present?
    scope = scope.where(id: ..max_user_id) if max_user_id.present?
    scope
  end

  def process(user)
    return if user.blocked? || user.discarded?

    logger.tagged(user_id: user.id, handle: user.handle) do
      YankRubygemsForUserJob.perform_later(user: user)
      user.block!
      logger.info "Yanked gems and blocked user"
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.error.report(e, context: { user_id: user.id }, handled: true)
  end

  private

  def matching_api_keys
    ApiKey.where(owner_type: "User")
      .where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(api_key_name)}%")
      .where(created_at: created_within_hours.hours.ago..)
  end

  def max_user_id_not_before_min
    return if min_user_id.blank? || max_user_id.blank?
    return if max_user_id >= min_user_id

    errors.add(:max_user_id, "must be greater than or equal to min_user_id")
  end
end
