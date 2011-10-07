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
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      post :create, :rubygem_id => @rubygem.to_param
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :success
    should "toggle the subscribe link" do
      assert_match /\("\.toggler"\)\.toggle\(\)/, @response.body
    end
  end

  context "On POST to create for a gem that the user is subscribed to" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      Factory(:subscription, :rubygem => @rubygem, :user => @user)
      post :create, :rubygem_id => @rubygem.to_param
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is not subscribed to" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      delete :destroy, :rubygem_id => @rubygem.to_param
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is subscribed to" do
    setup do
      @rubygem = Factory(:rubygem)
      Factory(:version, :rubygem => @rubygem)
      Factory(:subscription, :rubygem => @rubygem, :user => @user)
      delete :destroy, :rubygem_id => @rubygem.to_param
    end

    should assign_to(:rubygem) { @rubygem }
    should respond_with :success
    should "toggle the subscribe link" do
      assert_match /\("\.toggler"\)\.toggle\(\)/, @response.body
    end
  end
end
