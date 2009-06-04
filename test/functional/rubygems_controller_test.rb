require 'test_helper'

class RubygemsControllerTest < ActionController::TestCase

  context "When logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "On GET to mine with being signed in" do
      setup do
        3.times { Factory(:rubygem) }
        @gems = (1..3).map { Factory(:rubygem, :user => @user) }
        get :mine
      end

      should_respond_with :success
      should_render_template :mine
      should_assign_to(:gems) { @gems }
      should "render links" do
        @gems.each do |g|
          assert_contain g.name
          assert_have_selector "a[href='#{rubygem_path(g)}']"
        end
      end
    end

    context "On GET to show for another user's gem" do
      setup do
        @gem = Factory(:rubygem)
        get :show, :id => @gem.to_param
      end

      should_respond_with :success
      should_render_template :show
      should_assign_to :gem
      should "not render edit link" do
        assert_not_contain "Edit Gem"
        assert_have_no_selector "a[href='#{edit_rubygem_path(@gem)}']"
      end
    end

    context "On GET to show for this user's gem" do
      setup do
        @gem = Factory(:rubygem, :user => @user)
        get :show, :id => @gem.to_param
      end

      should_respond_with :success
      should_render_template :show
      should_assign_to :gem
      should "render edit link" do
        assert_contain "Edit Gem"
        assert_have_selector "a[href='#{edit_rubygem_path(@gem)}']"
      end
    end

    context "On GET to edit for this user's gem" do
      setup do
        @gem = Factory(:rubygem, :user => @user)
        get :edit, :id => @gem.to_param
      end

      should_respond_with :success
      should_render_template :edit
      should_assign_to :gem
      should "render form" do
        assert_have_selector "form"
        assert_have_selector "input#linkset_code"
        assert_have_selector "input#linkset_docs"
        assert_have_selector "input#linkset_wiki"
        assert_have_selector "input#linkset_mail"
        assert_have_selector "input#linkset_bugs"
        assert_have_selector "input[type='submit']"
      end
    end

    context "On GET to edit for another user's gem" do
      setup do
        @other_user = Factory(:email_confirmed_user)
        @gem = Factory(:rubygem, :user => @other_user)
        get :edit, :id => @gem.to_param
      end
      should_respond_with :redirect
      should_assign_to(:linkset) { @linkset }
      should_redirect_to('the homepage') { root_url }
      should_set_the_flash_to "You do not have permission to edit this gem."
    end

    context "On PUT to update for this user's gem that is successful" do
      setup do
        @gem = Factory(:rubygem, :user => @user)
        @url = "http://github.com/qrush/gemcutter"
        put :update, :id => @gem.to_param, :linkset => {:code => @url}
      end
      should_respond_with :redirect
      should_redirect_to('the gem') { rubygem_path(@gem) }
      should_set_the_flash_to "Gem links updated."
      should_assign_to(:linkset) { @linkset }
      should "update linkset" do
        assert_equal @url, Rubygem.find(@gem.to_param).linkset.code
      end
    end

    context "On PUT to update for this user's gem that fails" do
      setup do
        @gem = Factory(:rubygem, :user => @user)
        @url = "totally not a url"
        put :update, :id => @gem.to_param, :linkset => {:code => @url}
      end
      should_respond_with :success
      should_render_template :edit
      should_assign_to(:linkset) { @linkset }
      should "not update linkset" do
        assert_not_equal @url, Rubygem.find(@gem.to_param).linkset.code
      end
      should "render error messages" do
        assert_contain /error(s)? prohibited/m
      end
    end
  end

  [:new, :migrate, :search].each do |page|
    context "On GET to #{page}" do
      setup do
        get page
      end
      should_respond_with :success
      should_render_template page
    end
  end

  context "On GET to mine without being signed in" do
    setup { get :mine }
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end

  context "On GET to edit without being signed in" do
    setup do
      @rubygem = Factory(:rubygem)
      get :edit, :id => @rubygem.to_param
    end
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end

  context "On PUT to update without being signed in" do
    setup do
      @rubygem = Factory(:rubygem)
      put :update, :id => @rubygem.to_param, :linkset => {}
    end
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end

  context "On GET to index" do
    setup do
      @gems = (1..3).map { Factory(:rubygem) }
      get :index
    end

    should_respond_with :success
    should_render_template :index
    should_assign_to(:gems) { @gems }
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
      @current_version = @gem.current_version
      get :show, :id => @gem.to_param
    end

    should_respond_with :success
    should_render_template :show
    should_assign_to :gem
    should "render info about the gem" do
      assert_contain @gem.name
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
      @current_version = @gem.current_version
      get :show, :id => @gem.to_param
    end

    should_respond_with :success
    should_render_template :show
    should_assign_to :gem
    should "render info about the gem" do
      assert_contain @gem.name
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
      assert_match "Access Denied. Please sign up for an account at http://gemcutter.org", @response.body
    end
  end

  context "On POST to create with unconfirmed user" do
    setup do
      @user = Factory(:user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
      post :create
    end
    should "deny access" do
      assert_response 403
      assert_match "Access Denied. Please confirm your Gemcutter account.", @response.body
    end
  end

  context "with a confirmed user authenticated" do
    setup do
      @user = Factory(:email_confirmed_user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "On POST to create for new gem" do
      setup do
        @request.env["RAW_POST_DATA"] = gem_file.read
        post :create
      end
      should_respond_with :success
      should_assign_to(:_current_user) { @user }
      should_change "Rubygem.count", :by => 1
      should "register new gem" do
        assert_equal @user, Rubygem.last.user
        assert_equal "Successfully registered new gem: test (0.0.0)", @response.body
      end
    end

    context "On POST to create for existing gem" do
      setup do
        @rubygem = Factory(:rubygem, :user => @user, :name => "test")
        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        post :create
      end
      should_respond_with :success
      should_assign_to(:_current_user) { @user }
      should "register new version" do
        assert_equal @user, Rubygem.last.user
        assert_equal 2, Rubygem.last.versions.size
        assert_equal "Successfully registered new gem: test (1.0.0)", @response.body
      end
    end

    context "On POST to create with bad gem" do
      setup do
        stub(Rubygem).pull_spec(anything) { nil }
        @request.env["RAW_POST_DATA"] = gem_file.read
        post :create
      end
      should_respond_with 422
      should_not_change "Rubygem.count"
      should "not register gem" do
        assert_equal "Gemcutter cannot process this gem. Please try rebuilding it and installing it locally to make sure it's valid.", @response.body
      end
    end

    context "On POST to create for someone else's gem" do
      setup do
        @other_user = Factory(:email_confirmed_user)
        @rubygem = Factory(:rubygem, :user => @other_user, :name => "test")
        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        post :create
      end
      should_respond_with 403
      should_assign_to(:_current_user) { @user }
      should "not allow new version to be saved" do
        assert_equal @other_user, Rubygem.last.user
        assert_equal 1, Rubygem.last.versions.size
        assert_equal "You do not have permission to push to this gem.", @response.body
      end
    end
  end
end

