class Avo::Dashboards::Dashy < Avo::Dashboards::BaseDashboard
  self.id = "dashy"
  self.name = "Avo::Dashboards::Dashy"
  self.grid_cols = 6
  self.visible = lambda {
    current_user.team_member?("rubygems-org")
  }

  def cards
    card Avo::Cards::DashboardWelcomeCard

    divider label: "Metrics"

    card Avo::Cards::UsersMetric
    card Avo::Cards::VersionsMetric
    card Avo::Cards::RubygemsMetric

    divider label: "Charts"

    card Avo::Cards::PushesChart
  end
end
