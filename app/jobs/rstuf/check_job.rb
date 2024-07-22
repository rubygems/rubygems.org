class Rstuf::CheckJob < Rstuf::ApplicationJob
  RetryException = Class.new(StandardError)
  FailureException = Class.new(StandardError)
  ErrorException = Class.new(StandardError)
  retry_on RetryException, wait: :polynomially_longer, attempts: 10

  queue_with_priority PRIORITIES.fetch(:push)

  def perform(task_id)
    case status = Rstuf::Client.task_state(task_id)
    when "SUCCESS"
      # no-op, all good
    when "FAILURE"
      raise FailureException, "RSTUF job failed, please check payload and retry"
    when "ERRORED", "REVOKED", "REJECTED"
      raise ErrorException, "RSTUF internal problem, please check RSTUF health"
    when "PENDING", "RUNNING", "RECEIVED", "STARTED"
      raise RetryException
    else
      Rails.logger.info "RSTUF job returned unexpected state #{status}"
      raise RetryException
    end
  end
end
