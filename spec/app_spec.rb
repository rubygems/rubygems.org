require File.join(File.dirname(__FILE__), 'spec_helper')

describe Gem::App do
  it "should have a homepage" do
    mock(Gem::Cutter).count { 24_000 }
    get "/"
    last_response.status.should == 200
    last_response.body.should =~ /24,000/
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
        cutter = "cutter"
        stub(Gem::Cutter).new { cutter }
        stub(cutter).spec { @gem }
        stub(cutter).exists { false }
        mock(cutter).process
        mock(Gem::Cutter).indexer.stub!.update_index
        post '/gems', {}, {'rack.input' => gem_file("test-0.0.0.gem") }
      end

      it "should alert user that gem was created" do
        last_response.body.should == "New gem 'test' registered."
        last_response.status.should == 201
      end
    end

    it "should list installed gems" do
      mock(Gem::Cutter).find_all { [ ["test", Gem::Version.new("0.0.0"), "ruby"] ] }
      get "/gems"
      last_response.status.should == 200
      last_response.body.should =~ /test/
    end

    describe "On GET to /gems/test" do
      before do
        mock(Gem::Cutter).find("test") { @gem }
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
        cutter = "cutter"
        stub(Gem::Cutter).new { cutter }
        stub(cutter).spec { @gem }
        stub(cutter).exists { true }
        mock(cutter).process
        mock(Gem::Cutter).indexer.stub!.update_index
        post '/gems', {}, {'rack.input' => gem_file("test-0.0.0.gem_up") }
      end

      it "should alert user that gem was updated" do
        last_response.body.should == "Gem 'test' version 0.0.0 updated."
        last_response.status.should == 200
      end
    end
  end
end
