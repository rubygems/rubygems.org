module Rstuf
  class RemoveJob < Rstuf::ApplicationJob
    queue_with_priority PRIORITIES.fetch(:push)

    def perform(version:)
      task_id = Rstuf::Client.delete_artifacts([version.gem_file_name])
      Rstuf::CheckJob.set(wait: 10.seconds).perform_later(task_id)
    end
  end
end
