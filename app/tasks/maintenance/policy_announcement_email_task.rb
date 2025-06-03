# frozen_string_literal: true

class Maintenance::PolicyAnnouncementEmailTask < MaintenanceTasks::Task
  def collection
    User.where("id > ?", 10_333)
  end

  def process(user)
    PoliciesMailer.policy_update_announcement(user).deliver_later(queue: :within_24_hours)
  end

  delegate :count, to: :User
end
