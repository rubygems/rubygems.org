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
      assert_received(@command) { |command| command.setup }
      assert_received(@command) { |command| command.send_gem }
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.send_gem
      end
    end

    context "pushing a gem" do
      setup do
        @url = "https://gemcutter.org/api/v1/gems"
        @gem_path = "path/to/foo-0.0.0.gem"
        @gem_binary = StringIO.new("gem")

        stub(@command).say
        stub(@command).options { {:args => [@gem_path]} }
        stub(Gem).read_binary(@gem_path) { @gem_binary }
        stub_config({ :rubygems_api_key => "key" })
        stub_request(:post, @url).to_return(:body => "Success!")

        @command.send_gem
      end

      should "say push was successful" do
        assert_received(@command) { |command| command.say("Pushing gem to Gemcutter...") }
        assert_received(@command) { |command| command.say("Success!") }
      end

      should "post to api" do
        # webmock doesn't pass body params on correctly :[
        assert_requested(:post, @url,
                         :times => 1)
        assert_requested(:post, @url,
                         :headers => {'Authorization' => 'key' })
        assert_requested(:post, @url,
                         :headers => {'Content-Length' => @gem_binary.size})
        assert_requested(:post, @url,
                         :headers => {'Content-Type' => 'application/octet-stream'})
      end
    end
  end
end
