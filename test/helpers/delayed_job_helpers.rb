module DelayedJobHelpers
  def queued_job_classes
    Delayed::Job
      .all
      .pluck(:handler)
      .map { |handler| YAML.load(handler).class }
      .to_set
  end
end
