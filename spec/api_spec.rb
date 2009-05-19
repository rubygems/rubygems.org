require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter API" do
  before do
    FileUtils.rm_rf Dir["server/cache/*", "server/*specs*", "server/quick", "server/specifications/*"]
    Gem::Cutter.indexer.generate_index
  end

  it "should have a homepage" do
    get "/"
    last_response.status.should == 200
  end

  describe "with a valid gem" do
    before do
      @gem = "test-0.0.0.gem"
      @gem_file = gem_file(@gem)
      @cache_path = Gem::Cutter.server_path("cache", @gem)
      @spec_path = Gem::Cutter.server_path("specifications", @gem + "spec")
    end

    describe "with a saved gem" do
      before do
        FileUtils.cp @gem_file.path, @cache_path
        spec = Gem::Installer.new(@cache_path, :unpack => true).spec.to_ruby
        File.open(@spec_path, "w") { |f| f.write spec }
      end

      it "should list installed gems" do
        get "/gems"
        last_response.status.should == 200
        last_response.body.should =~ /test \(0.0.0\)/
      end

      describe "On GET to /gems/test" do
        before do
          get "/gems/test"
        end

        it "should return information about the gem" do
          last_response.body.should contain("test")
          last_response.body.should contain("0.0.0")
          last_response.status.should == 200
        end
      end

      describe "on POST to /gems with existing gem" do
        before do
          @gem_up = "test-0.0.0.gem_up"
          @gem_up_file = gem_file(@gem_up)
          post '/gems', {}, {'rack.input' => @gem_up_file}
        end

        it "should save gem and update index" do
          File.exists?(@cache_path).should be_true
          File.exists?(@spec_path).should be_true
          FileUtils.compare_file(@gem_up_file.path, @cache_path).should be_true
          File.exists?(Gem::Cutter.server_path("quick", "Marshal.4.8", "#{@gem}spec.rz")).should be_true
        end

        it "should alert user that gem was updated" do
          last_response.body.should == "Gem 'test' version 0.0.0 updated."
          last_response.status.should == 200
        end
      end
    end

    describe "on POST to /gems" do
      before do
        post '/gems', {}, {'rack.input' => @gem_file}
      end

      it "should save gem and update index" do
        File.exists?(@cache_path).should be_true
        File.exists?(@spec_path).should be_true
        FileUtils.compare_file(@gem_file.path, @cache_path).should be_true
        File.exists?(Gem::Cutter.server_path("quick", "Marshal.4.8", "#{@gem}spec.rz")).should be_true
      end

      it "should alert user that gem was created" do
        last_response.body.should == "New gem 'test' registered."
        last_response.status.should == 201
      end
    end

    it "should not save an empty gem" do
#      @temp_path = "temp path"
#
#      stub(Tempfile).new("gem").stub!.path { @temp_path }
#      mock(File).size(@temp_path) { 0 }
#
#      post '/gems', {}, {'rack.input' => @gem_file}
#      last_response.body.should == "Invalid gem file"
#      last_response.status.should == 500
    end
  end
end
