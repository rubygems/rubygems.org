class Dashy < Avo::Dashboards::BaseDashboard
  self.id = "dashy"
  self.name = "Dashy"
  self.grid_cols = 6
  self.visible = lambda {
    current_user.team_member?("rubygems-org")
  }

  # cards go here
  card DashboardWelcomeCard

  divider label: "Metrics"

  card UsersMetric
  card VersionsMetric
  card RubygemsMetric

  divider label: "Charts"

  card PushesChart
end
