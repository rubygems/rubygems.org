require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::Cutter do
  before do
    @data = "data"
    @cutter = Gem::Cutter.new("data")
  end

  it "should store data" do
    @cutter.data.should == @data
  end
end
