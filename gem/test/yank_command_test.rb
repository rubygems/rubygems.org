require 'helper'

class YankCommandTest < CommandTest
  context "yanking" do
    setup do
      @gem = "MyGem"
      @version = '0.1.0'
      @command = Gem::Commands::YankCommand.new
      stub(@command).say
    end

    %w[-v --version].each do |option|
      should "raise an error with no version with #{option}" do
        assert_raise OptionParser::MissingArgument do
          @command.handle_options([@gem, option])
        end
      end
    end

    context 'yanking a gem' do
      setup do
        stub_api_key("key")
        @api = "https://rubygems.org/api/v1/gems/yank"
        stub_request(:delete, @api).to_return(:body => "Successfully yanked")
        @command.handle_options([@gem, "-v", @version])
      end

      should 'say gem was yanked' do
        @command.execute
        assert_received(@command) do |command|
          command.say("Yanking gem from Gemcutter...")
          command.say("Successfully yanked")
        end
      end
      
      should 'invoke yank_gem' do
        stub(@command).yank_gem(@version)
        @command.execute
        assert_received(@command) do |command|
          command.yank_gem(@version)
        end
      end

      should 'delete to api' do
        @command.execute
        assert_requested(:delete, @api,
                         :times => 1)
        assert_requested(:delete, @api,
                         :headers => { 'Authorization' => 'key' })
      end
    end
    
    context 'unyanking a gem' do
      setup do
        stub_api_key("key")
        @api = "https://rubygems.org/api/v1/gems/unyank"
        stub_request(:put, @api).to_return(:body => "Successfully unyanked")
        @command.handle_options([@gem, "-v", @version, "--undo"])
      end
      
      should 'say gem was unyanked' do
        @command.execute
        assert_received(@command) do |command|
          command.say("Re-indexing gem")
          command.say("Successfully unyanked")
        end
      end

      should 'invoke unyank_gem' do
        stub(@command).unyank_gem(@version)
        @command.execute
        assert_received(@command) do |command|
          command.unyank_gem(@version)
        end
      end
      
      should 'put to api' do
        @command.execute
        assert_requested(:put, @api, :times => 1)
        assert_requested(:put, @api, :headers => { 'Authorization' => 'key' })
      end
    end
  end
end
