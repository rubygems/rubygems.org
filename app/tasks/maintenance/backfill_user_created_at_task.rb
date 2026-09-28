# frozen_string_literal: true

class Maintenance::BackfillUserCreatedAtTask < MaintenanceTasks::Task
  # https://github.com/rubygems/rubygems.org/commit/d9352f6a1d06c7b6442b9196436e99038bcf90a8
  TIMESTAMPS_INTRODUCED_AT = Time.utc(2009, 10, 8, 13, 30, 18)

  def collection
    User.with_deleted.where(created_at: nil)
  end

  def process(user)
    User.with_deleted.where(id: user.id, created_at: nil).update_all(created_at: TIMESTAMPS_INTRODUCED_AT)
  end
end
