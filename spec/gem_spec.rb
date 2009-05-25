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
    mock(@command).say("Upgrading your primary gem source to gems.gemcutter.org")
    mock(Gem).configuration.mock!.write
  end

  it "should upgrade to gemcutter" do
    @command.execute
    Gem.sources.include?("http://gems.gemcutter.org").should be_true
    Gem.sources.include?("http://gems.rubyforge.org").should be_false
  end
end

describe Gem::Commands::DowngradeCommand do
  before do
    @command = Gem::Commands::DowngradeCommand.new
    mock(@command).say("Your primary gem source is now gems.rubyforge.org")
    mock(Gem).configuration.mock!.write
  end

  it "should return to using rubyforge" do
    @command.execute
    Gem.sources.include?("http://gems.rubyforge.org").should be_true
    Gem.sources.include?("http://gems.gemcutter.org").should be_false
  end
end
