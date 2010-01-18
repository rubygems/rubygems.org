require 'test_helper'

class Api::V1::RubygemsControllerTest < ActionController::TestCase
  should_forbid_access_when("pushing a gem") { post :create }

  should "route old paths to new controller" do
    get_route = {:controller => 'api/v1/rubygems', :action => 'show', :id => "rails", :format => "json"}
    assert_recognizes(get_route, '/api/v1/gems/rails.json')

    post_route = {:controller => 'api/v1/rubygems', :action => 'create'}
    assert_recognizes(post_route, :path => '/api/v1/gems', :method => :post)
  end

  context "When logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "On GET to show for a gem that's hosted" do
      setup do
        @rubygem = Factory(:rubygem)
        Factory(:version, :rubygem => @rubygem)
        get :show, :id => @rubygem.to_param, :format => "json"
      end

      should_assign_to(:rubygem) { @rubygem }
      should_respond_with :success
      should "return a json hash" do
        assert_not_nil JSON.parse(@response.body)
      end
      should "include dependencies in the json" do
        gem = JSON.parse(@response.body)
        assert [], gem["dependencies"]["development"]
        assert [], gem["dependencies"]["runtime"]
      end
    end

    context "On GET to show for a gem that doesn't match the slug" do
      setup do
        @rubygem = Factory(:rubygem, :name => "ZenTest", :slug => "zentest")
        Factory(:version, :rubygem => @rubygem)
        get :show, :id => "ZenTest", :format => "json"
      end

      should_assign_to(:rubygem) { @rubygem }
      should_respond_with :success
      should "return a json hash" do
        assert_not_nil JSON.parse(@response.body)
      end
    end


    context "On GET to show for a gem that not hosted" do
      setup do
        @rubygem = Factory(:rubygem)
        assert 0, @rubygem.versions.count
        get :show, :id => @rubygem.to_param, :format => "json"
      end

      should_assign_to(:rubygem) { @rubygem }
      should_respond_with :not_found
      should "say not be found" do
        assert_match /does not exist/, @response.body
      end
    end

    context "On GET to show for a gem that doesn't exist" do
      setup do
        @name = Factory.next(:name)
        assert ! Rubygem.exists?(:name => @name)
        get :show, :id => @name, :format => "json"
      end

      should_respond_with :not_found
      should "say the rubygem was not found" do
        assert_match /not be found/, @response.body
      end
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
      should_change("the rubygem count") { Rubygem.count }
      should "register new gem" do
        assert_equal @user, Rubygem.last.ownerships.first.user
        assert_equal "Successfully registered gem: test (0.0.0)", @response.body
      end
    end

    context "On POST to create for existing gem" do
      setup do
        rubygem = Factory(:rubygem,
                            :name       => "test")
        Factory(:ownership, :rubygem    => rubygem,
                            :user       => @user,
                            :approved   => true)
        Factory(:version,   :rubygem    => rubygem,
                            :number     => "0.0.0",
                            :updated_at => 1.year.ago,
                            :created_at => 1.year.ago)

        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        post :create
      end
      should_respond_with :success
      should_assign_to(:_current_user) { @user }
      should "register new version" do
        assert_equal @user, Rubygem.last.ownerships.first.user
        assert_equal 1, Rubygem.last.ownerships.count
        assert_equal 2, Rubygem.last.versions.count
        assert_equal "Successfully registered gem: test (1.0.0)", @response.body
      end
    end

    context "On POST to create with bad gem" do
      setup do
        @request.env["RAW_POST_DATA"] = "really bad gem"
        post :create
      end
      should_respond_with :unprocessable_entity
      should_not_change("the rubygem count") { Rubygem.count }
      should "not register gem" do
        assert_match /Gemcutter cannot process this gem/, @response.body
      end
    end

    context "On POST to create for someone else's gem" do
      setup do
        @other_user = Factory(:email_confirmed_user)
        create_gem(@other_user, :name => "test")
        @rubygem.reload

        @request.env["RAW_POST_DATA"] = gem_file("test-1.0.0.gem").read
        post :create
      end
      should_respond_with 403
      should_assign_to(:_current_user) { @user }
      should "not allow new version to be saved" do
        assert_equal 1, @rubygem.ownerships.size
        assert_equal @other_user, @rubygem.ownerships.first.user
        assert_equal 1, @rubygem.versions.size
        assert_equal "You do not have permission to push to this gem.", @response.body
      end
    end
  end
end
