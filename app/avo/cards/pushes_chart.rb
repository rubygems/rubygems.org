class PushesChart < Avo::Dashboards::ChartkickCard
  self.id = "pushes_chart"
  self.label = "Pushes by day"
  self.chart_type = :line_chart
  # self.description = "Some tiny description"
  self.cols = 2
  self.rows = 2
  # self.initial_range = 30
  # self.ranges = {
  #   "7 days": 7,
  #   "30 days": 30,
  #   "60 days": 60,
  #   "365 days": 365,
  #   Today: "TODAY",
  #   "Month to date": "MTD",
  #   "Quarter to date": "QTD",
  #   "Year to date": "YTD",
  #   All: "ALL",
  # }
  # self.chart_options = { library: { plugins: { legend: { display: true } } } }
  # self.flush = true

  def query
    result Version.group_by_period(:day, :created_at, last: 30).count
  end
end
