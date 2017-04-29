require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  setup do
    @rubygem = create(:rubygem, number: "0.0.1")
    @user = create(:user)
    sign_in_as(@user)
  end

  context "On POST to create for a gem that the user is not subscribed to" do
    setup do
      post :create, rubygem_id: @rubygem.to_param
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem) }
    should "not set flash error" do
      assert_nil flash[:error]
    end
  end

  context "On POST to create for a gem that the user is subscribed to" do
    setup do
      create(:subscription, rubygem: @rubygem, user: @user)
      post :create, rubygem_id: @rubygem.to_param
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem) }
    should "set flash error" do
      assert_equal flash[:error], "Something went wrong. Please try again."
    end
  end

  context "On DELETE to destroy for a gem that the user is not subscribed to" do
    setup do
      delete :destroy, rubygem_id: @rubygem.to_param
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem) }
    should "set flash error" do
      assert_equal flash[:error], "Something went wrong. Please try again."
    end
  end

  context "On DELETE to destroy for a gem that the user is subscribed to" do
    setup do
      create(:subscription, rubygem: @rubygem, user: @user)
      delete :destroy, rubygem_id: @rubygem.to_param
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem) }
    should "not set flash error" do
      assert_nil flash[:error]
    end
  end
end
