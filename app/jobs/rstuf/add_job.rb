module Rstuf
  class AddJob < Rstuf::ApplicationJob
    queue_with_priority PRIORITIES.fetch(:push)

    def perform(version:)
      target = {
        info: {
          length: version.size,
          hashes: {
            sha256: version.sha256_hex
          }
        },
        path: version.gem_file_name
      }

      task_id = Rstuf::Client.post_artifacts([target])
      Rstuf::CheckJob.set(wait: 10.seconds).perform_later(task_id)
    end
  end
end
