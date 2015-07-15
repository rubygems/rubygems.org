require 'test_helper'

class DashboardsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on GET to show" do
      setup do
        3.times { create(:rubygem) }
        @gems = (1..3).map do
          rubygem = create(:rubygem)
          rubygem.ownerships.create(user: @user)
          create(:version, rubygem: rubygem)
          rubygem
        end
        get :show
      end

      should respond_with :success
      should render_template :show
      should "render links" do
        @gems.each do |g|
          assert page.has_content?(g.name)
          assert page.has_selector?("a[href='#{rubygem_path(g)}'][title='#{g.versions.most_recent.info}']")
        end
      end
    end

    context "On GET to show as an atom feed" do
      setup do
        @subscribed_versions = (1..2).map { |n| create(:version, created_at: n.hours.ago) }
        # just to make sure one has a different platform and a summary
        @subscribed_versions << create(:version, created_at: 3.hours.ago, platform: "win32", summary: "&")
        @subscribed_versions.each { |v| create(:subscription, rubygem: v.rubygem, user: @user)}
        @unsubscribed_versions = (1..3).map { |n| create(:version, created_at: n.hours.ago) }

        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        get :show, format: "atom"
      end

      should respond_with :success
      should render_template 'versions/feed'

      should "render posts with platform-specific titles and links of all subscribed versions" do
        @subscribed_versions.each do |v|
          assert_select "entry > title", count: 1, text: v.to_title
          assert_select "entry > link[href='#{rubygem_version_url(v.rubygem, v.slug)}']", count: 1
          assert_select "entry > id", count: 1, text: rubygem_version_url(v.rubygem, v.slug)
        end
      end

      should "render valid entry authors" do
        @subscribed_versions.each do |v|
          assert_select "entry > author > name", text: v.authors
        end
      end

      should "render entry summaries only for versions with summaries" do
        assert_select "entry > summary", count: @subscribed_versions.select {|v| v.summary? }.size
        @subscribed_versions.each do |v|
          assert_select "entry > summary", text: v.summary if v.summary?
        end
      end

      should "not render posts for versions the user isn't subscribed to" do
        assert_select "entry", @subscribed_versions.size
        @unsubscribed_versions.each do |v|
          assert_does_not_contain @response.body, v.to_title
        end
      end
    end
  end

  context "On GET to show without being signed in" do
    setup { get :show }
    should respond_with :redirect
    should redirect_to('the homepage') { root_url }
  end
end
