require 'test_helper'

class DashboardsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = Factory(:email_confirmed_user)
      sign_in_as(@user)
    end

    context "on GET to show" do
      setup do
        3.times { Factory(:rubygem) }
        @gems = (1..3).map do
          rubygem = Factory(:rubygem)
          rubygem.ownerships.create(:user => @user, :approved => true)
          rubygem
        end
        get :show
      end

      should_respond_with :success
      should_render_template :show
      should_assign_to(:my_gems) { @gems }
      should "render links" do
        @gems.each do |g|
          assert_contain g.name
          assert_have_selector "a[href='#{rubygem_path(g)}']"
        end
      end
    end

    context "On GET to show as an atom feed" do
      setup do
        @subscribed_versions = (1..3).map { |n| Factory(:version, :created_at => n.hours.ago) }
        @subscribed_versions.each { |v| Factory(:subscription, :rubygem => v.rubygem, :user => @user)}
        @unsubscribed_versions = (1..3).map { |n| Factory(:version, :created_at => n.hours.ago) }
        get :show, :format => "atom"
      end

      should_respond_with :success
      should_render_template 'versions/feed'
      should_assign_to(:versions) { @versions }
      should "render posts with titles and links of all subscribed versions" do
        @subscribed_versions.each do |v|
          assert_contain v.to_title
          assert_have_selector "link[href='#{rubygem_url(v.rubygem)}']"
        end
      end
      should "not render posts for versions the user isn't subscribed to" do
        @unsubscribed_versions.each do |v|
          assert_does_not_contain @response.body, v.to_title
        end
      end
    end
  end

  context "On GET to show without being signed in" do
    setup { get :show }
    should_respond_with :redirect
    should_redirect_to('the homepage') { root_url }
  end
end
