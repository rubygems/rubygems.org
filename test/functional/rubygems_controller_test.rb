require 'test_helper'

class RubygemsControllerTest < ActionController::TestCase
  context "On GET to index" do
    setup do
      @gems = (1..3).map { Factory(:rubygem) }
      get :index
    end

    should_respond_with :success
    should_render_template :index
    should_assign_to :gems
    should "render links" do
      @gems.each do |g|
        assert_contain g.name
        assert_have_selector "a[href='#{rubygem_path(g)}']"
      end
    end
  end

  context "On GET to show" do
    setup do
      @gem = Factory(:rubygem)
      @current_version = @gem.versions.first
      get :show, :id => @gem.to_param
    end

    should_respond_with :success
    should_render_template :show
    should_assign_to :gem
    should_assign_to :current_version
    should "render info about the gem" do
      assert_contain @gem.name
      assert_contain @current_version.description
      assert_contain @current_version.number
      assert_contain @current_version.created_at.to_date.to_formatted_s(:long)
      assert_not_contain "Versions"
    end
  end

  context "On GET to show with a gem that has multiple versions" do
    setup do
      @gem = Factory(:rubygem)
      @version = Factory(:version, :number => "1.0.0", :rubygem => @gem)
      @gem.reload
      @current_version = @gem.versions.first
      get :show, :id => @gem.to_param
    end

    should_respond_with :success
    should_render_template :show
    should_assign_to :gem
    should_assign_to :current_version
    should "render info about the gem" do
      assert_contain @gem.name
      assert_contain @current_version.description
      assert_contain @current_version.number
      assert_contain @current_version.created_at.to_date.to_formatted_s(:long)

      assert_contain "Versions"
      assert_contain @gem.versions.last.number
      assert_contain @gem.versions.last.created_at.to_date.to_formatted_s(:long)
    end
  end

  context "On POST to create with no user credentials" do
    setup do
      post :create
    end
    should "deny access" do
      assert_response 401
      assert_match "HTTP Basic: Access denied.", @response.body
    end
  end

  context "On POST to create with valid user credentials" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + 
        Base64::encode64("#{@user.email}:#{@user.password}")
      @request.env["RAW_POST_DATA"] = gem_file.read
      post :create
    end
    should_respond_with :success
    should_assign_to(:_current_user) { @user }
    should_change "Rubygem.count", :by => 1
    should "register new gem" do
      assert_equal @user, Rubygem.last.user
      assert_equal "Successfully registered new gem 'test'", @response.body
    end
  end
end

