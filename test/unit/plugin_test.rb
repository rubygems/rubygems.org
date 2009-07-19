require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'redgreen'
require 'fakeweb'
require 'rr'

FakeWeb.allow_net_connect = false

require File.join("lib", "rubygems_plugin")
%w(push upgrade downgrade).each do |command|
  require File.join("lib", "commands", command)
end

class PluginTest < Test::Unit::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)

  context "pushing" do
    setup do
      @command = Gem::Commands::PushCommand.new
      stub(@command).say
    end

    should "sign in then push if no api key" do
      stub(Gem).configuration { {:gemcutter_key => nil} }
      mock(@command).sign_in
      mock(@command).send_gem
      @command.execute
    end

    should "not sign in if api key exists" do
      stub(Gem).configuration { {:gemcutter_key => "1234567890"} }
      mock(@command).sign_in.never
      mock(@command).send_gem
      @command.execute
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.send_gem
      end
    end

    context "signing in" do
      setup do
        @email = "email"
        @password = "password"
        @key = "key"
        mock(@command).say("Enter your Gemcutter credentials. Don't have an account yet? Create one at #{URL}/sign_up")
        mock(@command).ask("Email: ") { @email }
        mock(@command).ask_for_password("Password: ") { @password }
        FakeWeb.register_uri :get, "http://#{@email}:#{@password}@gemcutter.org/api_key", :body => @key

        @config = Object.new
        stub(Gem).configuration { @config }
        stub(@config)[:gemcutter_key] = @key
        stub(@config).write
      end

      should "sign in" do
        mock(@command).say("Signed in. Your api key has been stored in ~/.gemrc")
        @command.sign_in
      end

      should "let the user know if there was a problem" do
        @problem = "Access Denied"
        mock(@command).say(@problem)
        mock(@command).terminate_interaction
        mock(@config).write.never

        FakeWeb.register_uri :get, "http://#{@email}:#{@password}@gemcutter.org/api_key", :body => @problem, :status => 401
        @command.sign_in
      end
    end

    should "push a gem" do
      mock(@command).say("Pushing gem to Gemcutter...")
      @response = "success"
      FakeWeb.register_uri :post, "http://gemcutter.org/gems", :body => @response

      @gem = "test"
      @io = "io"
      @config = { :gemcutter_key => "key" }

      stub(File).open(@gem) { @io }
      stub(@io).read.stub!.size

      stub(@command).options { {:args => [@gem]} }
      stub(Gem).configuration { @config }

      mock(@command).say(@response)
      @command.send_gem
    end
  end

  context "upgrading" do
    setup do
      @sources = ["http://rubyforge.org"]
      stub(Gem).sources { @sources }
      @config = Object.new
      stub(Gem).configuration { @config }

      @command = Gem::Commands::UpgradeCommand.new
    end

    should "add gemcutter as first source" do
      mock(@command).say("Your primary gem source is now gemcutter.org")
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
