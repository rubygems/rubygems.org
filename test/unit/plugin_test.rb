require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'redgreen'
gem 'fakeweb', '>= 1.2.5'
require 'fakeweb'
require 'rr'

FakeWeb.allow_net_connect = false

require File.join("lib", "rubygems_plugin")
%w(push tumble).each do |command|
  require File.join("lib", "commands", command)
end

class PluginTest < Test::Unit::TestCase
  include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)

  context "pushing" do
    setup do
      @command = Gem::Commands::PushCommand.new
      stub(@command).say
    end
    
    should "use a proxy if specified" do
      stub(Gem).configuration { { :http_proxy => 'http://some.proxy' } }
      mock(@command).use_proxy!
      mock(@command).sign_in
      mock(@command).send_gem
      @command.execute
    end
    
    should "not use a proxy if unspecified" do
      stub(Gem).configuration { { :http_proxy => nil } }
      mock(@command).use_proxy!.never
      mock(@command).sign_in
      mock(@command).send_gem
      @command.execute
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
    
    context "parsing the proxy" do
      
      should "return nil if no proxy is set" do
        stub(Gem).configuration { { :http_proxy => nil } }
        assert_equal nil, @command.http_proxy
      end
      
      should "return nil if the proxy is set to :no_proxy" do
        stub(Gem).configuration { { :http_proxy => :no_proxy } }
        assert_equal nil, @command.http_proxy
      end
      
      should "return a proxy as a URI if set" do
        stub(Gem).configuration { { :http_proxy => 'http://proxy.example.org:9192' } }
        assert_equal 'proxy.example.org', @command.http_proxy.host
        assert_equal 9192, @command.http_proxy.port
      end
      
    end
    
    context "using the proxy" do
      setup do
        stub(Gem).configuration { { :http_proxy => "http://gilbert:sekret@proxy.example.org:8081" } }
        @proxy_class = Object.new
        mock(Net::HTTP).Proxy('proxy.example.org', 8081, 'gilbert', 'sekret') { @proxy_class }
        @command.use_proxy!
      end
      
      should "replace Net::HTTP with a proxy version" do
        assert_equal @proxy_class, Net::HTTP
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
        FakeWeb.register_uri :get, "https://#{@email}:#{@password}@gemcutter.heroku.com/api_key", :body => @key

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

        FakeWeb.register_uri :get, "https://#{@email}:#{@password}@gemcutter.heroku.com/api_key", :body => @problem, :status => 401
        @command.sign_in
      end
    end

    should "push a gem" do
      mock(@command).say("Pushing gem to Gemcutter...")
      @response = "success"
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems", :body => @response

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

  context "with a tumbler and some sources" do
    setup do
      @sources = ["gems.rubyforge.org", URL]
      stub(Gem).sources { @sources }
      @command = Gem::Commands::TumbleCommand.new
    end

    should "show sources" do
      mock(@command).puts("Your gem sources are now:")
      mock(@command).puts("- #{@sources.first}")
      mock(@command).puts("- #{URL}")
      @command.show_sources
    end
  end

  context "tumbling the gem sources" do
    setup do
      @sources = ["http://rubyforge.org"]
      stub(Gem).sources { @sources }
      @config = Object.new
      stub(Gem).configuration { @config }

      @command = Gem::Commands::TumbleCommand.new
    end

    should "add gemcutter as first source" do
      mock(@sources).unshift(URL)
      mock(@config).write

      @command.tumble
    end

    should "remove gemcutter if it's in the sources" do
      mock(@sources).include?(URL) { true }
      mock(@config).write
      mock(@sources).delete(URL)

      @command.tumble
    end
  end

  context "executing the tumbler" do
    setup do
      @command = Gem::Commands::TumbleCommand.new
    end

    should "say thanks, tumble and show the sources" do
      mock(@command).say(anything)
      mock(@command).tumble
      mock(@command).show_sources

      @command.execute
    end
  end
end
