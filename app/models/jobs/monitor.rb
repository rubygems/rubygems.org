module Jobs
  class Monitor

    def alert_error(job, exception)
      Rails.logger.error "Error in job #{job.class.name}"
      Rails.logger.error exception.backtrace
    end
  end
end
