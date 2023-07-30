# frozen_string_literal: true

class Maintenance::UserTotpSeedEmptyToNilTask < MaintenanceTasks::Task
  def collection
    User.where(totp_seed: "")
  end

  def process(element)
    element.transaction do
      element.update!(totp_seed: nil) if element.totp_seed == ""
    end
  end

  delegate :count, to: :collection
end
