require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = Factory(:user)
      sign_in_as(@user)
    end
  end

  context "On POST to create for a gem that the user is not subscribed to" do
    setup do
      @gem = Factory(:rubygem)
      Factory(:version, :rubygem => @gem)
      post :create, :rubygem_id => @gem.to_param, :format => 'js'
    end

    should assign_to(:gem) { @gem }
    should respond_with :success
    should "toggle the subscribe link" do
      assert_match /\("\.toggler"\)\.toggle\(\)/, @response.body
    end
  end

  context "On POST to create for a gem that the user is subscribed to" do
    setup do
      @gem = Factory(:rubygem)
      Factory(:version, :rubygem => @gem)
      Factory(:subscription, :rubygem => @gem, :user => @user)
      post :create, :rubygem_id => @gem.to_param, :format => 'js'
    end

    should assign_to(:gem) { @gem }
    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is not subscribed to" do
    setup do
      @gem = Factory(:rubygem)
      Factory(:version, :rubygem => @gem)
      delete :destroy, :rubygem_id => @gem.to_param, :format => 'js'
    end

    should assign_to(:gem) { @gem }
    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is subscribed to" do
    setup do
      @gem = Factory(:rubygem)
      Factory(:version, :rubygem => @gem)
      Factory(:subscription, :rubygem => @gem, :user => @user)
      delete :destroy, :rubygem_id => @gem.to_param, :format => 'js'
    end

    should assign_to(:gem) { @gem }
    should respond_with :success
    should "toggle the subscribe link" do
      assert_match /\("\.toggler"\)\.toggle\(\)/, @response.body
    end
  end
end
