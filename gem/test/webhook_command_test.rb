require 'command_helper'

class WebhookCommandTest < CommandTest
  context "webhooking" do
    setup do
      @command = Gem::Commands::WebhookCommand.new
      stub(@command).say
    end

    should "setup and post hook" do
      mock(@command).setup
      mock(@command).post_webhook
      @command.execute
    end
    
    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.post_webhook
      end
    end
    
    should "push a gem" do
      mock(@command).say("Registering webhook...")
      @response = "success"
      FakeWeb.register_uri :post, "https://gemcutter.org/api/v1/webhooks", :body => @response
    
      @gem = "test"
      @config = { :gemcutter_key => "key" }
    
      stub(@command).options { {:args => ["#{@gem} -u http://example.org/gem_hooks"]} }
      stub(Gem).configuration { @config }
    
      mock(@command).say(@response)
      @command.post_webhook
    end
  end
end
