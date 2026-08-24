# frozen_string_literal: true

class Maintenance::BackfillUserWebauthnIdsTask < MaintenanceTasks::Task
  def collection
    User.where(webauthn_id: nil).where.missing(:webauthn_credentials)
  end

  def process(user)
    User.transaction do
      locked_user = User.lock.find_by(id: user.id)
      next unless locked_user && locked_user.webauthn_id_in_database.nil?
      next if locked_user.webauthn_credentials.exists?

      locked_user.update_column(:webauthn_id, WebAuthn.generate_user_id)
    end
  end

  delegate :count, to: :collection
end
