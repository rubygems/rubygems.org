class HookRelayReportJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :good_job
  queue_with_priority PRIORITIES.fetch(:stats)

  class UnknownStatusError < StandardError
  end

  class MalformedStreamError < StandardError
  end

  discard_on UnknownStatusError
  discard_on MalformedStreamError

  before_perform do
    stream = arguments[0].fetch(:stream)
    id = stream.slice(/:webhook_id-(\d+)\z/, 1)
    raise MalformedStreamError, stream.inspect unless id
    @hook = WebHook.unscoped.find(id.to_i)
  end

  def perform(params)
    completed_at = params.fetch(:completed_at).to_datetime

    case params.fetch(:status)
    when "failure"
      @hook.failure!(completed_at:)
    when "success"
      @hook.success!(completed_at:)
    else
      raise UnknownStatusError, params.fetch(:status).inspect
    end
  end
end
