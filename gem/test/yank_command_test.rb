require 'command_helper'

class YankCommandTest < CommandTest
  context "yanking" do
    setup do
      @command = Gem::Commands::YankCommand.new
      stub(@command).say
      stub_config({ :rubygems_api_key => "key" })
    end

    should "setup and yank the gem" do
      mock(@command).setup
      mock(@command).get_version_from_requirements(version_requirement).returns("0.1.0")
      mock(@command).yank_gem("0.1.0")
      @command.invoke("SomeGem", "--version", "0.1.0")
      assert_received(@command) { |command| command.setup }
      assert_received(@command) { |command| command.get_version_from_requirements(version_requirement) }
      assert_received(@command) { |command| command.yank_gem("0.1.0") }
    end
    
    should "not yank a gem because of a missing version" do
      mock(@command).setup
      mock(@command).yank_gem.returns { raise Exception.new("should not call #yank_gem") }
      @command.invoke("SomeGem")
      assert_received(@command) { |command| command.setup }
    end
    
    should "yank a gem" do
      url = "https://gemcutter.org/api/v1/gems/MyGem/yank"
      
      mock(@command).say("Yanking gem from Gemcutter...")
      stub(@command).options { {:args => ["MyGem"], :version => version_requirement} }
      stub_request(:delete, url).to_return(:body => "Successfully yanked")
    
      @command.yank_gem(version_requirement)
      assert_received(@command) { |command| command.say("Yanking gem from Gemcutter...") }
      assert_received(@command) { |command| command.say("Successfully yanked") }
    end
  end
  
  private
    def version_requirement
      Gem::Requirement.new(Gem::Version.new("0.1.0"))
    end
end
