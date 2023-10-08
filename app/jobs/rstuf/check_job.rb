module Rstuf
  class CheckJob < Rstuf::ApplicationJob
    RetryException = Class.new(StandardError)
    retry_on RetryException

    queue_with_priority PRIORITIES.fetch(:push)

    def perform(task_id)
      case Rstuf::Client.task_status(task_id)
      when "SUCCESS"
        # no-op, all good
      when "FAILURE"
        raise "rstuf failed"
      else
        raise RetryException
      end
    end
  end
end
