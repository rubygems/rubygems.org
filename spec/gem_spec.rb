require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rubygems_plugin'

describe Gem::Commands::PushCommand do
  before do
    @command = Gem::Commands::PushCommand.new
    mock(@command).say("Pushing gem to Gemcutter...")
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

describe Gem::Commands::UpgradeCommand do
  before do
    @command = Gem::Commands::UpgradeCommand.new
    mock(@command).say("Upgrading your primary gem source to gemcutter.org")
    stub(Gem).sources { ["http://gems.rubyforge.org"] }
  end

  it "should upgrade to gemcutter" do
    @command.execute
  end
end
