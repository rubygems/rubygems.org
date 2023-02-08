class Dashy < Avo::Dashboards::BaseDashboard
  self.id = "dashy"
  self.name = "Dashy"
  # self.description = "Tiny dashboard description"
  # self.grid_cols = 3
  self.visible = lambda {
    current_user.team_member?("rubygems-org")
  }

  # cards go here
  card DashboardWelcomeCard

  card UsersMetric
  card PushesChart
end
