require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'redgreen'
require 'fakeweb'
require 'rr'

FakeWeb.allow_net_connect = false

require "lib/rubygems_plugin"
%w(push upgrade downgrade).each do |command|
  require "lib/commands/#{command}"
end

class PluginTest < Test::Unit::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)

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
      @email = "email"
      @password = "password"
      @key = "key"
      mock(@command).say("Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up")
      mock(@command).ask("Email: ") { @email }
      mock(@command).ask_for_password("Password: ") { @password }
      FakeWeb.register_uri :get, "http://#{@email}:#{@password}@gemcutter.org/token", :string => @key

      @config = Object.new
      stub(Gem).configuration { @config }
      mock(@config)[:gemcutter_key] = @key
    end

    should "add gemcutter as first source" do
      mock(@config).write.times(2)
      mock(@command).say("Upgrading your primary gem source to gemcutter.org")
      @command.execute
      assert_equal "http://gemcutter.org", Gem.sources.first
      assert Gem.sources.include?("http://gems.rubyforge.org")
    end

    should "only add gemcutter once" do
      mock(@config).write
      mock(@command).say("Gemcutter is already your primary gem source. Please use `gem downgrade` if you wish to no longer use Gemcutter.")
      @command.execute
      assert_equal "http://gemcutter.org", Gem.sources.first
      assert !Gem.sources[1..-1].include?("http://gemcutter.org")
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
