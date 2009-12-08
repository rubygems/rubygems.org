require 'command_helper'

class PushCommandTest < CommandTest
  context "pushing" do
    setup do
      @command = Gem::Commands::PushCommand.new
      stub(@command).say
    end

    should "setup and send the gem" do
      mock(@command).setup
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
      FakeWeb.register_uri :post, "https://gemcutter.org/api/v1/gems", :body => @response

      @gem = "test"
      @io = "io"
      @config = { :gemcutter_key => "key" }

      stub(File).open(@gem, "rb") { @io }
      stub(@io).read.stub!.size

      stub(@command).options { {:args => [@gem]} }
      stub_config(@config)

      mock(@command).say(@response)
      @command.send_gem
    end
  end
end
