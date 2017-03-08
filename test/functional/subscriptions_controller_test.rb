require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end
  end

  context "On POST to create for a gem that the user is not subscribed to" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)
      post :create, rubygem_id: @rubygem.to_param, format: 'js'
    end

    should respond_with :success
    should "toggle the subscribe link" do
      assert_includes @response.body, 'Subscribe'
    end
  end

  context "On POST to create for a gem that the user is subscribed to" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)
      create(:subscription, rubygem: @rubygem, user: @user)
      post :create, rubygem_id: @rubygem.to_param, format: 'js'
    end

    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is not subscribed to" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)
      delete :destroy, rubygem_id: @rubygem.to_param, format: 'js'
    end

    should respond_with :forbidden
  end

  context "On DELETE to destroy for a gem that the user is subscribed to" do
    setup do
      @rubygem = create(:rubygem)
      create(:version, rubygem: @rubygem)
      create(:subscription, rubygem: @rubygem, user: @user)
      delete :destroy, rubygem_id: @rubygem.to_param, format: 'js'
    end

    should respond_with :success
    should "toggle the subscribe link" do
      assert_includes @response.body, 'Subscribe'
    end
  end
end
