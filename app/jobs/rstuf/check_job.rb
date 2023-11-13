class Rstuf::CheckJob < Rstuf::ApplicationJob
  RetryException = Class.new(StandardError)
  FailureException = Class.new(StandardError)
  retry_on RetryException, wait: :exponentially_longer, attempts: 10

  queue_with_priority PRIORITIES.fetch(:push)

  def perform(task_id)
    case status = Rstuf::Client.task_status(task_id)
    when "SUCCESS"
      # no-op, all good
    when "FAILURE"
      raise FailureException, "RSTUF job failed"
    when "PENDING"
      raise RetryException
    else
      Rails.logger.info "RSTUF job returned unexpected state #{status}"
      raise RetryException
    end
  end
end
