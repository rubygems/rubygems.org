# frozen_string_literal: true

class Maintenance::BackfillUserWebauthnIdsTask < MaintenanceTasks::Task
  attribute :min_user_id, :integer
  attribute :max_user_id, :integer

  validate :max_user_id_not_before_min

  def collection
    scope = User.where(webauthn_id: nil).where.missing(:webauthn_credentials)
    scope = scope.where(id: min_user_id..) if min_user_id.present?
    scope = scope.where(id: ..max_user_id) if max_user_id.present?
    scope
  end

  def process(user)
    User.transaction do
      locked_user = User.lock.find_by(id: user.id)
      next unless locked_user && locked_user.webauthn_id_in_database.nil?
      next if locked_user.webauthn_credentials.exists?

      locked_user.update_column(:webauthn_id, WebAuthn.generate_user_id)
    end
  end

  private

  def max_user_id_not_before_min
    return if min_user_id.blank? || max_user_id.blank?
    return if max_user_id >= min_user_id

    errors.add(:max_user_id, "must be greater than or equal to min_user_id")
  end
end
