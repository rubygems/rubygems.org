require 'test_helper'

class DashboardsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "On GET to mine" do
      setup do
        3.times { Factory(:rubygem) }
        @gems = (1..3).map do
          rubygem = Factory(:rubygem)
          rubygem.ownerships.create(:user => @user, :approved => true)
          rubygem
        end
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

    context "On GET to subscribed" do
      setup do
        3.times { Factory(:rubygem) }
        @gems = (1..3).map do
          rubygem = Factory(:rubygem)
          rubygem.subscriptions.create(:user => @user)
          rubygem
        end
        get :subscribed
      end

      should_respond_with :success
      should_render_template :subscribed
      should_assign_to(:gems) { @gems }
      should "render links" do
        @gems.each do |g|
          assert_contain g.name
          assert_have_selector "a[href='#{rubygem_path(g)}']"
        end
      end
    end
  end

  context "On GET to mine without being signed in" do
    setup { get :mine }
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end

  context "On GET to subscribed without being signed in" do
    setup { get :subscribed }
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end
end
