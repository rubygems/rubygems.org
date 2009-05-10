require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter API" do
  it "should create index on startup" do
    %w[latest_specs.4.8 prerelease_specs.4.8 specs.4.8].each do |file|
      File.exists?(Gemcutter.server_path(file)).should be_true
    end
  end

  describe "on POST to /gems" do
    before do
      @gem = "test-0.0.0.gem"
      @gem_file = gem_file(@gem)

      post '/gems', {}, {'rack.input' => @gem_file}
    end

    it "should save gem into cache folder" do
      cache_path = Gemcutter.server_path("cache", @gem)
      File.exists?(cache_path).should be_true
      FileUtils.compare_file(@gem_file.path, cache_path).should be_true
    end

    it "should save the gemspec" do
      spec_path = Gemcutter.server_path("specifications", @gem + "spec")
      File.exists?(spec_path).should be_true
    end

    it "should alert user that gem was created" do
      last_response.body.should == "#{@gem} registered."
      last_response.status.should == 201
    end

    it "should update index" do
      File.exists?(Gemcutter.server_path("quick", "Marshal.4.8", "#{@gem}spec.rz")).should be_true
    end
  end
end
