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
      FakeWeb.register_uri :post, "http://gemcutter.org/gems", :string => @response
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.execute
      end
    end

    should "push a gem" do
      @gem = "test"
      @io = "io"
      @config = { :gemcutter_key => "key" }

      stub(File).open(@gem) { @io }
      stub(@io).read.stub!.size

      stub(@command).options { {:args => [@gem]} }
      stub(Gem).configuration { @config }

      mock(@command).say(@response)
      @command.execute
    end
  end

  context "upgrading" do
    setup do
      @sources = ["http://rubyforge.org"]
      stub(Gem).sources { @sources }

      @command = Gem::Commands::UpgradeCommand.new
      @email = "email"
      @password = "password"
      @key = "key"
      mock(@command).say("Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up")
      mock(@command).ask("Email: ") { @email }
      mock(@command).ask_for_password("Password: ") { @password }
      FakeWeb.register_uri :get, "http://#{@email}:#{@password}@gemcutter.org/api_key", :string => @key

      @config = Object.new
      stub(Gem).configuration { @config }
      stub(@config)[:gemcutter_key] = @key
      stub(@config).write
    end

    should "let the user know if there was a problem" do
      @problem = "Access Denied"
      mock(@command).say("Upgrading your primary gem source to gemcutter.org")
      mock(@command).say(@problem)
      mock(@config).write.never

      FakeWeb.register_uri :get, "http://#{@email}:#{@password}@gemcutter.org/api_key", :string => @problem, :status => 401
      @command.execute
    end

    should "add gemcutter as first source" do
      mock(@command).say("Upgrading your primary gem source to gemcutter.org")
      mock(@sources).unshift(URL)
      mock(@config).write
      @command.execute
    end

    should "only add gemcutter once" do
      mock(@sources).include?(URL) { true }
      mock(@command).say("Gemcutter is already your primary gem source. Please use `gem downgrade` if you wish to no longer use Gemcutter.")
      mock(@config).write.never
      @command.execute
    end
  end

  context "downgrading" do
    setup do
      @command = Gem::Commands::DowngradeCommand.new
    end

    should "return to using rubyforge" do
      mock(@command).say("Your primary gem source is now gems.rubyforge.org")
      mock(Gem).configuration.mock!.write
      mock(Gem).sources.mock!.delete(URL)
      @command.execute
    end
  end
end
