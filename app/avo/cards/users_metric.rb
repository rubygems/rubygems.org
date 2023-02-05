class UsersMetric < Avo::Dashboards::MetricCard
  self.id = "users_metric"
  self.label = "Total users"
  # self.description = "Some description"
  self.cols = 1
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
  # self.prefix = ""
  # self.suffix = ""

  def query
    # from = Date.today.midnight - 1.week
    # to = DateTime.current

    # if range.present?
    #   if range.to_s == range.to_i.to_s
    #     from = DateTime.current - range.to_i.days
    #   else
    #     case range
    #     when "TODAY"
    #       from = DateTime.current.beginning_of_day
    #     when "MTD"
    #       from = DateTime.current.beginning_of_month
    #     when "QTD"
    #       from = DateTime.current.beginning_of_quarter
    #     when "YTD"
    #       from = DateTime.current.beginning_of_year
    #     when "ALL"
    #       from = Time.at(0)
    #     end
    #   end
    # end

    result User.count
  end
end
