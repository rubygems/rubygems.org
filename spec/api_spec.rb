require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter API" do
  after do
    FileUtils.rm_rf(Dir[Gemcutter.server_path("cache", "*.gem")])
    FileUtils.rm_rf(Dir[Gemcutter.server_path("gems", "**", "*")])
    FileUtils.rm_rf(Dir[Gemcutter.server_path("specifications", "*.gemspec")])
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

    it "should unpack gem into gems folder" do
      gem_path = Gemcutter.server_path("gems", @gem.chomp(".gem"))
      File.directory?(gem_path).should be_true
      Dir[gem_path + "/**/*"].size.should_not be_zero
    end

    it "should alert user that gem was created" do
      last_response.body.should == "#{@gem} registered."
      last_response.status.should == 201
    end
  end
end
