require 'command_helper'
require 'net/scp'

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
      @token = "deadbeef"
      stub(@command).say
      stub(@command).find
      stub(@command).get_token { @token }
      stub(@command).upload_token
      stub(@command).check_for_approved
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
      assert_received(@command) { |subject| subject.upload_token(@token) }
      assert_received(@command) { |subject| subject.check_for_approved }
    end
  end

  context "ask about the gem" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      stub(@command).say
      stub(@command).terminate_interaction

      @name = "rails"
      @json = "{\"downloads\":4,\"name\":\"rails\",\"authors\":\"David Heinemeier Hansson\",\"version\":\"2.3.3\",\"rubyforge_project\":\"rails\",\"info\":\"Rails is a framework for building web-application using CGI, FCGI, mod_ruby, or WEBrick on top of either MySQL, PostgreSQL, SQLite, DB2, SQL Server, or Oracle with eRuby- or Builder-based templates.\"}"
    end

    should "find gem info if it exists" do
      FakeWeb.register_uri :get, "https://gemcutter.org/gems/#{@name}.json", :body => @json
      @command.find(@name)
      assert_equal JSON.parse(@json), @command.rubygem
    end

    should "dump out if the gem couldn't be found" do
      FakeWeb.register_uri :get, "https://gemcutter.org/gems/#{@name}.json", :body => "Not hosted here.", :status => 404
      @command.find(@name)
      assert_received(@command) { |subject| subject.say(anything) }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "dump out if bad json is returned" do
      FakeWeb.register_uri :get, "https://gemcutter.org/gems/#{@name}.json", :body => "bad data is bad"
      @command.find(@name)
      assert_received(@command) { |subject| subject.say(anything) }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "know the project name if it exists in the gem" do
      stub(@command).rubygem.with() { {'rubyforge_project' => 'rails'} }
      assert_equal 'rails', @command.project_name
    end

    should "fall back to the gem name when trying to find the rubyforge project" do
      stub(@command).rubygem.with() { {'name' => 'rails'} }
      assert_equal 'rails', @command.project_name
    end
  end

  context "getting the token" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      @name = "SomeGem"
      stub(@command).say
      stub(@command).terminate_interaction
      stub(@command).rubygem { { "name" => @name } }
    end

    should "ask gemcutter to start the migration" do
      token = "SECRET TOKEN"
      FakeWeb.register_uri :post, "https://gemcutter.org/gems/#{@name}/migrate", :body => token
      assert_equal token, @command.get_token
    end

    should "dump out if gem could not be found" do
      FakeWeb.register_uri :post, "https://gemcutter.org/gems/#{@name}/migrate", :status => 404, :body => "not found"
      @command.get_token
      assert_received(@command) { |subject| subject.say("not found") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end

    should "dump out if migration has already been completed" do
      FakeWeb.register_uri :post, "https://gemcutter.org/gems/#{@name}/migrate", :status => 403, :body => "already migrated"
      @command.get_token
      assert_received(@command) { |subject| subject.say("already migrated") }
      assert_received(@command) { |subject| subject.terminate_interaction }
    end
  end

  context "uploading the token" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      @token = "deadbeef"
      stub(@command).say
      stub(@command).rubygem { { "rubyforge_project" => "bostonrb" } }
      stub(Net::SCP).start
    end

    should "ask for username and password then connect to rubyforge and upload away" do
      stub(File).exists? { false }
      stub(@command).ask { "user" }
      stub(@command).ask_for_password { "secret" }
      @command.upload_token(@token)

      # TODO: figure out how to test the upload! in the block
      assert_received(Net::SCP) { |subject| subject.start("bostonrb.rubyforge.org", "user", :password => "secret") }
    end

    should "not ask for a username and password if it can be loaded from the user home" do
      stub(File).exists? { true }
      stub(YAML).load_file { { 'username' => "user", 'password' => "secret" } }
      @command.upload_token(@token)

      # TODO: figure out how to test the upload! in the block
      assert_received(Net::SCP) { |subject| subject.start("bostonrb.rubyforge.org", "user", :password => "secret") }
    end
  end

  context "checking if the rubygem was approved" do
    setup do
      @command = Gem::Commands::MigrateCommand.new
      @name = "rails"

      stub(@command).say
      stub(@command).rubygem { { "name" => @name } }
    end

    should "let the server decide the status" do
      FakeWeb.register_uri :put, "https://gemcutter.org/gems/#{@name}/migrate", :body => "Success!", :status => 400
      @command.check_for_approved
      assert_received(@command) { |subject| subject.say("Success!") }
    end
  end
end
