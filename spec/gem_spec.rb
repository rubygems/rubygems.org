require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Gemcutter Plugin" do
  before do
    @command = Gem::Commands::PushCommand.new
  end

  it "should raise an error with no arguments" do
    lambda {
      @command.execute
    }.should raise_error(Gem::CommandLineError)
  end

  it "should push a gem" do
    stub(@command).options { {:args => ["test"]} }

    @gem = "gem"
    mock(File).open("test") { @gem }
    mock(RestClient).post("http://gemcutter.org/gems", @gem)
    @command.execute
  end
end
