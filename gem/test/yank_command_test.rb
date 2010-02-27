require 'helper'

class YankCommandTest < CommandTest
  context "yanking" do
    setup do
      @gem = "MyGem"
      @version = '0.1.0'
      @api = "https://rubygems.org/api/v1/gems/#{@gem}/yank"
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
        stub_request(:delete, @api).to_return(:body => "Successfully yanked")
    
        @command.handle_options([@gem, "-v", @version])
        @command.execute
      end
      
      should 'say gem was yanked' do
        assert_received(@command) do |command|
          command.say("Yanking gem from Gemcutter...")
          command.say("Successfully yanked")
        end
      end
      
      should 'delete to api' do
        assert_requested(:delete, @api,
                         :times => 1)
        assert_requested(:delete, @api,
                         :headers => { 'Authorization' => 'key' })        
      end
    end
  end
end
