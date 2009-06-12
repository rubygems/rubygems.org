require File.dirname(__FILE__) + '/../spec_helper'

describe Ginger::Configuration do
  it "should be a singleton class" do
    Ginger::Configuration.should respond_to(:instance)
  end
end
