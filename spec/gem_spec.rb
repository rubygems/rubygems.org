require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rubygems_plugin'

describe "Gemcutter Plugin" do
  before do
    @command = Gem::Commands::PushCommand.new
    stub(@command).say("Pushing gem to Gemcutter...")
    @response = "success"
    FakeWeb.register_uri :post, "http://gemcutter.org/gems", :string => @response
  end

  it "should raise an error with no arguments" do
    lambda {
      @command.execute
    }.should raise_error(Gem::CommandLineError)
  end

  it "should push a gem" do
    @gem = "test"
    @io = "io"
    stub(@command).options { {:args => [@gem]} }
    stub(@io).read.stub!.size
    stub(File).open(@gem) { @io }

    mock(@command).say(@response)
    @command.execute
  end
end
