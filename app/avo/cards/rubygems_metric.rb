class RubygemsMetric < Avo::Dashboards::MetricCard
  self.id = "rubygems_metric"
  self.label = "RubyGems "
  self.cols = 2
  self.initial_range = "ALL"
  self.ranges = {
    "7 days": 7,
    "30 days": 30,
    "60 days": 60,
    "365 days": 365,
    Today: "TODAY",
    "Month to date": "MTD",
    "Quarter to date": "QTD",
    "Year to date": "YTD",
    All: "ALL"
  }

  def query
    from = Time.zone.today.midnight - 1.week
    to = Time.zone.now

    if range.present?
      if range.to_s == range.to_i.to_s
        from = to - range.to_i.days
      else
        case range
        when "TODAY"
          from = to.beginning_of_day
        when "MTD"
          from = to.beginning_of_month
        when "QTD"
          from = to.beginning_of_quarter
        when "YTD"
          from = to.beginning_of_year
        when "ALL"
          from = Time.zone.at(0)
        end
      end
    end

    result Rubygem.where(created_at: from..to).count
  end
end
