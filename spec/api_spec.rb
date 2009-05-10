require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter API" do
  after do
    FileUtils.rm_rf(Dir[Gemcutter.server_path("cache", "*.gem")])
  end

  describe "on POST to /gems" do
    it "should accept a built gem" do
      gem = "test-0.0.0.gem"
      post '/gems', gem_file(gem)
      File.exists?(Gemcutter.server_path("cache", gem)).should be_true
    end
  end

  it "should work" do
    get '/'
    @response.should =~ /gemcutter/
  end
end
