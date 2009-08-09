require File.dirname(__FILE__) + '/../../command_helper'

class PushCommandTest < CommandTest
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
end
