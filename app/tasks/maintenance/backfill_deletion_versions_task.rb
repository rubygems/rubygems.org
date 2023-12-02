# frozen_string_literal: true

class Maintenance::BackfillDeletionVersionsTask < MaintenanceTasks::Task
  include SemanticLogger::Loggable

  def collection
    Deletion.all
  end

  def process(deletion)
    return if deletion.version_id?

    if deletion.version.blank?
      logger.warn("Deletion does not have a matching version", deletion:)
    else
      deletion.update!(version_id: deletion.version.id)
    end
  end
end
