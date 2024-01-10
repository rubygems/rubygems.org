class Avo::Cards::DashboardWelcomeCard < Avo::Cards::PartialCard
  self.id = "dashboard_welcome_card"
  self.label = "Welcome to the RubyGems.org admin dashboard!"
  self.partial = "avo/cards/dashboard_welcome_card"
  self.display_header = true
  self.cols = 6
end
