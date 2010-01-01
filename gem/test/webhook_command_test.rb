require 'command_helper'

class WebhookCommandTest < CommandTest
  context "webhooking" do
    setup do
      @gem = "foo"
      @api = "https://gemcutter.org/api/v1/web_hooks"
      @url = "http://example.com/hook"
      @command = Gem::Commands::WebhookCommand.new
      stub(@command).say
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.execute
      end
    end

    context "adding a hook" do
      setup do
        stub(@command).say
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:post, @api).to_return(:body => "Success!")

        @command.handle_options([@gem, "-a", @url])
        @command.execute
      end

      should "say hook was added" do
        assert_received(@command) do |command|
          command.say("Adding webhook...")
          command.say("Success!")
        end
      end

      should "post to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:post, @api,
                         :times => 1)
        assert_requested(:post, @api,
                         :headers => { 'Authorization' => 'key' })
      end
    end

    context "removing a hook" do
      setup do
        stub(@command).say
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:delete, @api).to_return(:body => "Success!")

        @command.handle_options([@gem, "-r", @url])
        @command.execute
      end

      should "say hook was removed" do
        assert_received(@command) do |command|
          command.say("Removing webhook...")
          command.say("Success!")
        end
      end

      should "send delete to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:delete, @api,
                         :times => 1)
        assert_requested(:delete, @api,
                         :headers => { 'Authorization' => 'key' })
      end
    end
  end
end
