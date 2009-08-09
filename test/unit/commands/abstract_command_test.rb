require File.dirname(__FILE__) + '/../../command_helper'

class Gem::Commands::AbstractCommand < Gem::Command
  def initialize
    super 'abstract'
  end
end

class AbstractCommandTest < CommandTest
  context "pushing" do
    setup do
      @command = Gem::Commands::AbstractCommand.new
      stub(@command).say
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
  end
end
