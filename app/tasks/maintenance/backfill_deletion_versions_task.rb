# frozen_string_literal: true

class Maintenance::BackfillDeletionVersionsTask < MaintenanceTasks::Task
  def collection
    Deletion.all
  end

  def process(deletion)
    return if deletion.version_id?

    deletion.update!(version_id: deletion.version.id)
  end
end
