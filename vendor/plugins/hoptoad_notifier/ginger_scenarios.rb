require 'ginger'

def create_scenario(version)
  scenario = Ginger::Scenario.new
  scenario[/^active_?support$/]    = version
  scenario[/^active_?record$/]     = version
  scenario[/^action_?pack$/]       = version
  scenario[/^action_?controller$/] = version
  scenario
end

Ginger.configure do |config|
  config.aliases["active_record"] = "activerecord"
  config.aliases["active_support"] = "activesupport"
  config.aliases["action_controller"] = "actionpack"

  rails_1_2_6 = Ginger::Scenario.new
  rails_1_2_6[/^active_?support$/] = "1.4.4"
  rails_1_2_6[/^active_?record$/] = "1.15.6"
  rails_1_2_6[/^action_?pack$/] = "1.13.6"
  rails_1_2_6[/^action_?controller$/] = "1.13.6"

  config.scenarios << rails_1_2_6
  config.scenarios << create_scenario("2.0.2")
  config.scenarios << create_scenario("2.1.2")
  config.scenarios << create_scenario("2.2.2")
  config.scenarios << create_scenario("2.3.2")
end
