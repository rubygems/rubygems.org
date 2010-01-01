require 'command_helper'

class WebhookCommandTest < CommandTest
  context "webhooking" do
    setup do
      @command = Gem::Commands::WebhookCommand.new
      stub(@command).say
    end

    should "setup and post hook" do
      stub(@command).setup
      stub(@command).add_webhook
      @command.execute
      assert_received(@command) { |command| command.setup }
      assert_received(@command) { |command| command.add_webhook }
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.add_webhook
      end
    end

    context "adding a hook" do
      setup do
        @url = "https://gemcutter.org/api/v1/web_hooks"
        stub(@command).say
        stub(@command).options { {:args => ["#{@gem} -a http://example.org/gem_hooks"]} }
        stub_config({ :rubygems_api_key => "key" })
        WebMock.stub_request(:post, @url).to_return(:body => "Success!")

        @command.add_webhook
      end

      should "say hook was added" do
        assert_received(@command) { |command| command.say("Registering webhook...") }
        assert_received(@command) { |command| command.say("Success!") }
      end

      should "post to api" do
        # webmock doesn't pass body params on correctly :[
        WebMock.assert_requested(:post, @url, 
                                 :times => 1)
        WebMock.assert_requested(:post, @url,
                                 :headers => { 'Authorization' => 'key' })
      end
    end
  end
end
