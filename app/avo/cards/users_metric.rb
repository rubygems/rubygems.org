class UsersMetric < Avo::Dashboards::MetricCard
  self.id = "users_metric"
  self.label = "Total users"
  self.cols = 2

  def query
    result User.count
  end
end
