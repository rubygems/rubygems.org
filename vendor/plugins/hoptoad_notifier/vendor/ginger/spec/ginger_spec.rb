require File.dirname(__FILE__) + '/spec_helper'

describe "Ginger" do
  it "should add scenarios to the Configuration instance" do
    Ginger.configure do |config|
      scenario = Ginger::Scenario.new
      scenario["riddle"] = "0.9.8"
      
      config.scenarios << scenario
    end
    
    Ginger::Configuration.instance.scenarios.length.should == 1
  end
end
