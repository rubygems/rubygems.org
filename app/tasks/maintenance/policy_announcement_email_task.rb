# frozen_string_literal: true

class Maintenance::PolicyAnnouncementEmailTask < MaintenanceTasks::Task
  def collection
    User.order(id: :asc)
  end

  def process(user)
    Mailer.policy_update_announcement(user).deliver_now
  end

  delegate :count, to: :User
end
