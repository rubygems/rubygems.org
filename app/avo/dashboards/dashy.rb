class Dashy < Avo::Dashboards::BaseDashboard
  self.id = "dashy"
  self.name = "Dashy"
  # self.description = "Tiny dashboard description"
  # self.grid_cols = 3
  self.visible = -> do
    current_user.team_member?("rubygems-org")
  end

  # cards go here
  card DashboardWelcomeCard

  card UsersMetric
  card PushesChart
end
