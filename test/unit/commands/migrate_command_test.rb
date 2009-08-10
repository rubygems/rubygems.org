require File.dirname(__FILE__) + '/../../command_helper'

class MigrateCommandTest < CommandTest
  context "executing the command" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      stub(@command).setup
      stub(@command).migrate
    end

    should "setup and send the gem" do
      @command.execute
      assert_received(@command) { |subject| subject.setup }
      assert_received(@command) { |subject| subject.migrate }
    end
  end

  context "migrating" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      stub(@command).say
      stub(@command).get_token
    end

    should "raise an error with no arguments" do
      assert_raise Gem::CommandLineError do
        @command.migrate
      end
    end

    should "migrate the gem" do
      stub(@command).get_one_gem_name { "mygem" }
      @command.migrate
      assert_received(@command) { |subject| subject.get_token("mygem") }
    end
  end

  context "getting the token" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      @name = "somegem"
      stub(@command).say
      stub(@command).terminate_interaction
    end

    should "ask gemcutter to start the migration" do
      token = "SECRET TOKEN"
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@name}/migrate", :body => token
      assert_equal token, @command.get_token(@name)
    end

    should "dump out if gem could not be found" do
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@name}/migrate", :status => 404, :body => "not found"
      @command.get_token(@name)
      assert_received(@command) { |subject| subject.say("not found") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "dump out if migration has already been completed" do
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@name}/migrate", :status => 403, :body => "already migrated"
      @command.get_token(@name)
      assert_received(@command) { |subject| subject.say("already migrated") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end
  end
end
