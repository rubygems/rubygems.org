class PushesChart < Avo::Dashboards::ChartkickCard
  self.id = "pushes_chart"
  self.label = "Pushes by day"
  self.chart_type = :line_chart
  self.cols = 6
  self.rows = 2

  def query
    result Version.group_by_period(:day, :created_at, last: 30).count
  end
end
