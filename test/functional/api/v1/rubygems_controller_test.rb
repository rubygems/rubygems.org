require 'test_helper'

class Api::V1::RubygemsControllerTest < ActionController::TestCase

  should "route old paths to new controller" do
    get_route = {:controller => 'api/v1/rubygems', :action => 'show', :id => "rails", :format => "json"}
    assert_recognizes(get_route, '/gems/rails.json')
    assert_recognizes(get_route, '/api/v1/gems/rails.json')
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
end
