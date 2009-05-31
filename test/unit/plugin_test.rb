require 'test_helper'
require 'rubygems_plugin'

class PluginTest < ActiveSupport::TestCase
  context "pushing" do
    setup do
      @command = Gem::Commands::PushCommand.new
      mock(@command).say("Pushing gem to Gemcutter...")
      @response = "success"
      FakeWeb.register_uri :post, "http://email:password@gemcutter.org/gems", :string => @response
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.execute
      end
    end

    should "push a gem" do
      @gem = "test"
      @io = "io"
      stub(@command).options { {:args => [@gem]} }
      stub(@io).read.stub!.size
      stub(File).open(@gem) { @io }

      mock(YAML).load_file(File.expand_path("~/.gemrc")) { {
        :gemcutter_email    => "email",
        :gemcutter_password => "password"
      } }

      mock(@command).say(@response)
      @command.execute
    end
  end

  context "upgrading" do
    setup do
      @command = Gem::Commands::UpgradeCommand.new
      mock(@command).say("Upgrading your primary gem source to gems.gemcutter.org")
      mock(Gem).configuration.mock!.write
    end

    should "upgrade to gemcutter" do
      @command.execute
      assert Gem.sources.include?("http://gemcutter.org")
      assert !Gem.sources.include?("http://gems.rubyforge.org")
    end
  end

  context "downgrading" do
    setup do
      @command = Gem::Commands::DowngradeCommand.new
      mock(@command).say("Your primary gem source is now gems.rubyforge.org")
      mock(Gem).configuration.mock!.write
    end

    should "return to using rubyforge" do
      @command.execute
      assert !Gem.sources.include?("http://gemcutter.org")
      assert Gem.sources.include?("http://gems.rubyforge.org")
    end
  end
end
