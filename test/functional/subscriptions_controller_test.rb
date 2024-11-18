require "test_helper"

class SubscriptionsControllerTest < ActionController::TestCase
  setup do
    @rubygem = create(:rubygem, number: "0.0.1")
    @user = create(:user)
    sign_in_as(@user)
  end

  context "on GET to index when the user is not subscribed to any gems" do
    setup do
      get :index
    end

    should respond_with :success

    should "render 'no subscriptions' message" do
      assert page.has_content?("You're not subscribed to any gems yet.")
    end
  end

  context "on GET to index when the user is subscribed" do
    setup do
      create(:subscription, rubygem: @rubygem, user: @user)
      get :index
    end

    should respond_with :success

    should "show the gem name" do
      assert page.has_content?(@rubygem.name)
    end
  end

  context "On POST to create for a gem that the user is not subscribed to" do
    setup do
      post :create, params: { rubygem_id: @rubygem.slug }
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem.slug) }

    should "not set flash error" do
      assert_nil flash[:error]
    end
  end

  context "On POST to create for a gem that the user is subscribed to" do
    setup do
      create(:subscription, rubygem: @rubygem, user: @user)
      post :create, params: { rubygem_id: @rubygem.slug }
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem.slug) }

    should "set flash error" do
      assert_equal "Something went wrong. Please try again.", flash[:error]
    end
  end

  context "On DELETE to destroy for a gem that the user is not subscribed to" do
    setup do
      delete :destroy, params: { rubygem_id: @rubygem.slug }
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem.slug) }

    should "set flash error" do
      assert_equal "Something went wrong. Please try again.", flash[:error]
    end
  end

  context "On DELETE to destroy for a gem that the user is subscribed to" do
    setup do
      create(:subscription, rubygem: @rubygem, user: @user)
      delete :destroy, params: { rubygem_id: @rubygem.slug }
    end

    should redirect_to("rubygems show") { rubygem_path(@rubygem.slug) }

    should "not set flash error" do
      assert_nil flash[:error]
    end
  end
end
