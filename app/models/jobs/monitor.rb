require 'dogapi'

module Jobs
  class Monitor

    def alert_error(job, exception)
      dog.emit_event(Dogapi::Event.new(error_message(job, exception),
                     msg_title: error_title(job, exception),
                     alert_type: "error",
                     tags: tags(job, exception)))
    end

    private

    def error_title(job, exception)
      "Job Error in #{job.class.name}"
    end

    def error_message(job, exception)
      exception.message
    end

    def tags(job, exception)
      [job.class.name, exception.class.name]
    end

    def dog
      @dog ||= Dogapi::Client.new(ENV['DATADOG_API_KEY'])
    end
  end
end
