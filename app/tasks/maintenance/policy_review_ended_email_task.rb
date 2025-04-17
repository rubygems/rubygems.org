class Maintenance::PolicyReviewEndedEmailTask < MaintenanceTasks::Task
  def collection
    User.all
  end

  def process(user)
    Mailer.policy_update_announcement(user).deliver_now
  end

  delegate :count, to: :User
end
