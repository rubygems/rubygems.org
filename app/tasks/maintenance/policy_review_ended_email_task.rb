class Maintenance::PolicyReviewEndedEmailTask < MaintenanceTasks::Task
  def collection
    User.all
  end

  def process(user)
    PoliciesMailer.policy_update_review_closed(user).deliver_later(queue: :within_24_hours)
  end

  delegate :count, to: :User
end
