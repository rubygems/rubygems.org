require 'test_helper'

class TestGeneratorInitialization < Test::Unit::TestCase
  def setup
    @project_name = 'the-perfect-gem'
    @git_name = 'foo'
    @git_email = 'bar@example.com'
    @github_user = 'technicalpickles'
    @github_token = 'zomgtoken'
  end

  def stub_git_config(options = {})
    stub(Git).global_config() { options }
  end

  def valid_git_config
    { 'user.name' => @git_name, 'user.email' => @git_email, 'github.user' => @github_user, 'github.token' => @github_token }
  end

  context "given a nil github repo name" do
    setup do
      stub_git_config

      @block = lambda {  }
    end

    should 'raise NoGithubRepoNameGiven' do
      assert_raise Jeweler::NoGitHubRepoNameGiven do
        Jeweler::Generator.new(nil)
      end
    end
  end

  context "without git user's name set" do
    setup do
      stub_git_config 'user.email' => @git_email
    end

    should 'raise an NoGitUserName' do
      assert_raise Jeweler::NoGitUserName do
        Jeweler::Generator.new(@project_name)
      end
    end
  end

  context "without git user's email set" do
    setup do
      stub_git_config 'user.name' => @git_name
    end

    should 'raise NoGitUserName' do
      assert_raise Jeweler::NoGitUserEmail do
        Jeweler::Generator.new(@project_name)
      end
    end
  end

  context "without github username set" do
    setup do
      stub_git_config 'user.email' => @git_email, 'user.name' => @git_name
    end

    should 'raise NotGitHubUser' do
      assert_raise Jeweler::NoGitHubUser do
        Jeweler::Generator.new(@project_name)
      end
    end
  end
  
  context "without github token set" do
    setup do
      stub_git_config 'user.name' => @git_name, 'user.email' => @git_email, 'github.user' => @github_user
    end

    should 'raise NoGitHubToken if creating repo' do
      assert_raise Jeweler::NoGitHubToken do
        Jeweler::Generator.new(@project_name, :create_repo => true)
      end
    end
  end

  context "default configuration" do
    setup do
      stub_git_config valid_git_config
      @generator = Jeweler::Generator.new(@project_name)
    end

    should "use shoulda for testing" do
      assert_equal :shoulda, @generator.testing_framework
    end

    should "use rdoc for documentation" do
      assert_equal :rdoc, @generator.documentation_framework
    end

    should "set todo in summary" do
      assert_match /todo/i, @generator.summary
    end

    should "set todo in description" do
      assert_match /todo/i, @generator.description
    end

    should "set target directory to the project name" do
      assert_equal @project_name, @generator.target_dir
    end

    should "set user's name from git config" do
      assert_equal @git_name, @generator.user_name
    end

    should "set email from git config" do
      assert_equal @git_email, @generator.user_email
    end

    should "set a github remote based on username and project name" do
      assert_equal "git@github.com:#{@github_user}/#{@project_name}.git", @generator.git_remote
    end

    should "set github username from git config" do
      assert_equal @github_user, @generator.github_username
    end

    should "set project name as the-perfect-gem" do
      assert_equal @project_name, @generator.project_name
    end
  end

  context "using yard" do
    setup do
      @generator = Jeweler::Generator.new(@project_name, :documentation_framework => :yard)
    end

    should "set the doc_task to yardoc" do
      assert_equal "yardoc", @generator.doc_task
    end

  end

  context "using yard" do
    setup do
      @generator = Jeweler::Generator.new(@project_name, :documentation_framework => :rdoc)
    end

    should "set the doc_task to rdoc" do
      assert_equal "rdoc", @generator.doc_task
    end
  end

  context "using options" do
    should "set documentation" do
      generator = Jeweler::Generator.new(@project_name, :documentation_framework => :yard)
      assert_equal :yard, generator.documentation_framework
    end
  end
end
