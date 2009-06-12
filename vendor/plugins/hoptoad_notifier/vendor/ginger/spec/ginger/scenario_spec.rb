require File.dirname(__FILE__) + '/../spec_helper'

describe Ginger::Scenario do
  it "should allow for multiple gem/version pairs" do
    scenario = Ginger::Scenario.new
    scenario.add "thinking_sphinx", "1.0"
    scenario.add "riddle",          "0.9.8"
    
    scenario.gems.should include("thinking_sphinx")
    scenario.gems.should include("riddle")
  end
  
  it "should be able to be used as a hash" do
    scenario = Ginger::Scenario.new
    scenario["thinking_sphinx"] = "1.0"
    scenario["riddle"] = "0.9.8"
    
    scenario.gems.should include("thinking_sphinx")
    scenario.gems.should include("riddle")
  end
  
  it "should allow gem names to be regular expressions" do
    scenario = Ginger::Scenario.new
    scenario.add /^active_?record$/, "2.1.0"
    
    scenario.gems.first.should be_kind_of(Regexp)
  end
  
  it "should return the appropriate version for a given gem" do
    scenario = Ginger::Scenario.new
    scenario.add "riddle", "0.9.8"
    
    scenario.version("riddle").should == "0.9.8"
  end
  
  it "should use regular expressions to figure out matching version" do
    scenario = Ginger::Scenario.new
    scenario[/^active_?record$/] = "2.1.0"
    
    scenario.version("activerecord").should  == "2.1.0"
    scenario.version("active_record").should == "2.1.0"
  end
  
  it "should return nil if no matching gem" do
    scenario = Ginger::Scenario.new
    scenario.add "riddle", "0.9.8"
    
    scenario.version("thinking_sphinx").should be_nil
  end
end
