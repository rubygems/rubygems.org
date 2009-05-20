require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::App do
  it "should have a homepage" do
    get "/"
    last_response.status.should == 200
  end

  describe "with a valid gem" do
    before do
      @gem = "gem"
      stub(@gem).name { "test" }
      stub(@gem).version { "0.0.0" }
      stub(@gem).date { Date.today }
      stub(@gem).authors { "Joe User" }
      stub(@gem).summary { "Awesome gem" }
    end

    describe "on POST to /gems" do
      before do
        stub(Gem::Cutter).new.stub!.save_gem { @gem }
        mock(Gem::Cutter).indexer.stub!.update_index
        post '/gems', {}, {'rack.input' => gem_file("test-0.0.0.gem") }
      end

      it "should alert user that gem was created" do
        last_response.body.should == "New gem 'test' registered."
        last_response.status.should == 201
      end
    end

    describe "with a saved gem" do
      before do
        stub(Gem::Cutter).find_gem("test") { @gem }
        stub(Gem::Cutter).list_gems { ["test (0.0.0)"] }
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
          stub(Gem::Cutter).new.stub!.save_gem { [@gem, true] }
          mock(Gem::Cutter).indexer.stub!.update_index
          post '/gems', {}, {'rack.input' => gem_file("test-0.0.0.gem_up") }
        end

        it "should alert user that gem was updated" do
          last_response.body.should == "Gem 'test' version 0.0.0 updated."
          last_response.status.should == 200
        end
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
