require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter API" do
  it "should work" do
    get '/'
    @response.should =~ /gemcutter/
  end
end
