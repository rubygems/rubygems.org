class Internal::BackgroundJobStatsController < ActionController::Metal
  def stats
    total = Delayed::Job.count
    failed = Delayed::Job.where.not(failed_at: nil).count
    self.response_body = "total=#{total} failed=#{failed}"
  end
end
