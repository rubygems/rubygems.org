class Maintenance::BackfillUserPublicEmailTask < MaintenanceTasks::Task
  def collection
    User.in_batches
  end

  def process(users_batch)
    users_batch.update_all("public_email = NOT hide_email")
  end
end
