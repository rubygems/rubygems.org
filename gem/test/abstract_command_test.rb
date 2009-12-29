require 'command_helper'

class Gem::Commands::FakeCommand < Gem::AbstractCommand
  def description
    'fake command'
  end

  def initialize
    super 'fake', description
  end

  def execute
  end
end

class AbstractCommandTest < CommandTest
  context "with an fake command" do
    setup do
      @command = Gem::Commands::FakeCommand.new
      stub(@command).say
      ENV['http_proxy'] = nil
      ENV['HTTP_PROXY'] = nil
    end

    context "parsing the proxy" do
      should "return nil if no proxy is set" do
        stub_config(:http_proxy => nil)
        assert_equal nil, @command.http_proxy
      end

      should "return nil if the proxy is set to :no_proxy" do
        stub_config(:http_proxy => :no_proxy)
        assert_equal nil, @command.http_proxy
      end

      should "return a proxy as a URI if set" do
        stub_config(:http_proxy => 'http://proxy.example.org:9192')
        assert_equal 'proxy.example.org', @command.http_proxy.host
        assert_equal 9192, @command.http_proxy.port
      end

      should "return a proxy as a URI if set by environment variable" do
        ENV['http_proxy'] = "http://jack:duck@192.168.1.100:9092"
        assert_equal "192.168.1.100", @command.http_proxy.host
        assert_equal 9092, @command.http_proxy.port
        assert_equal "jack", @command.http_proxy.user
        assert_equal "duck", @command.http_proxy.password
      end
    end

    should "sign in if no api key" do
      stub(@command).api_key { nil }
      stub(@command).sign_in
      @command.setup
      assert_received(@command) { |command| command.sign_in }
    end

    should "not sign in if api key exists" do
      stub(@command).api_key { "1234567890" }
      stub(@command).sign_in
      @command.setup
      assert_received(@command) { |command| command.sign_in.never }
    end

    context "using the proxy" do
      setup do
        stub_config(:http_proxy => "http://gilbert:sekret@proxy.example.org:8081")
        @proxy_class = Object.new
        mock(Net::HTTP).Proxy('proxy.example.org', 8081, 'gilbert', 'sekret') { @proxy_class }
        @command.use_proxy!
      end

      should "replace Net::HTTP with a proxy version" do
        assert_equal @proxy_class, @command.proxy_class
      end
    end

    context "signing in" do
      setup do
        @email = "email"
        @password = "password"
        @key = "key"

        stub(@command).say
        stub(@command).ask { @email }
        stub(@command).ask_for_password { @password }
        stub_config(:rubygems_api_key => @key)
      end

      context "on a good request" do
        setup do
          WebMock.stub_request(:get, "https://#{@email}:#{@password}@gemcutter.org/api/v1/api_key").to_return(:body => @key)
        end

        should "ask for email and password" do
          @command.sign_in
          assert_received(@command) { |command| command.ask("Email: ") }
          assert_received(@command) { |command| command.ask_for_password("Password: ") }
        end

        should "say that we signed in" do
          @command.sign_in
          assert_received(@command) { |command| command.say("Signed in. Your api key has been stored in ~/.gem/credentials") }
          assert_received(@command) { |command| command.say("Enter your Gemcutter credentials. Don't have an account yet? Create one at http://gemcutter.org/sign_up") }
        end
      end

      context "on a bad request" do
        setup do
          @problem = "Access Denied"
          stub(@command).terminate_interaction
          stub(@command).send(:api_key=)
          WebMock.stub_request(:get, "https://#{@email}:#{@password}@gemcutter.org/api/v1/api_key").to_return(
            :body   => @problem,
            :status => 401)
        end

        should "let the user know there was a problem" do
          @command.sign_in
          assert_received(@command) { |command| command.say(@problem) }
        end

        should "kill the command" do
          @command.sign_in
          assert_received(@command) { |command| command.terminate_interaction }
        end

        should "not write anything to the credentials file" do
          @command.sign_in
          assert_received(@command) { |command| command.send(:api_key=).never }
        end
      end
    end
  end
end
