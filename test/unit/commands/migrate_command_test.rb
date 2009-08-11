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
      stub(@command).find
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
      assert_received(@command) { |subject| subject.find("mygem") }
      assert_received(@command) { |subject| subject.get_token }
    end
  end

  context "ask about the gem" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      stub(@command).say
      stub(@command).terminate_interaction

      @name = "rails"
      @json = "{\"downloads\":4,\"name\":\"rails\",\"slug\":\"rails\",\"authors\":\"David Heinemeier Hansson\",\"version\":\"2.3.3\",\"rubyforge_project\":\"rails\",\"info\":\"Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.\"}"
    end

    should "find gem info if it exists" do
      FakeWeb.register_uri :get, "https://gemcutter.heroku.com/gems/#{@name}.json", :body => @json
      @command.find(@name)
      assert_equal JSON.parse(@json), @command.rubygem
    end

    should "dump out if the gem couldn't be found" do
      FakeWeb.register_uri :get, "https://gemcutter.heroku.com/gems/#{@name}.json", :body => "Not hosted here.", :status => 404
      @command.find(@name)
      assert_received(@command) { |subject| subject.say(anything) }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "dump out if bad json is returned" do
      FakeWeb.register_uri :get, "https://gemcutter.heroku.com/gems/#{@name}.json", :body => "bad data is bad"
      @command.find(@name)
      assert_received(@command) { |subject| subject.say(anything) }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

  end

  context "getting the token" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      @name = "SomeGem"
      @name = "somegem"
      stub(@command).say
      stub(@command).terminate_interaction
      stub(@command).rubygem { { "name" => @name, "slug" => @slug } }
    end

    should "ask gemcutter to start the migration" do
      token = "SECRET TOKEN"
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@slug}/migrate", :body => token
      assert_equal token, @command.get_token
    end

    should "dump out if gem could not be found" do
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@slug}/migrate", :status => 404, :body => "not found"
      @command.get_token
      assert_received(@command) { |subject| subject.say("not found") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "dump out if migration has already been completed" do
      FakeWeb.register_uri :post, "https://gemcutter.heroku.com/gems/#{@slug}/migrate", :status => 403, :body => "already migrated"
      @command.get_token
      assert_received(@command) { |subject| subject.say("already migrated") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end
  end
end
