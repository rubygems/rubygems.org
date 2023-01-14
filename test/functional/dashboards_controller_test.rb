require "test_helper"

class DashboardsControllerTest < ActionController::TestCase
  context "When not logged in" do
    context "with show dashboard api key scope" do
      setup do
        api_key = create(:api_key, key: "12345", show_dashboard: true)
        @subscribed_version = create(:version, created_at: 1.hour.ago)
        create(:subscription, rubygem: @subscribed_version.rubygem, user: api_key.user)

        get :show, params: { api_key: "12345" }, format: "atom"
      end

      context "On GET to show as an atom feed with a working api_key" do
        should respond_with :success

        should "render an XML feed with subscribed items" do
          assert_select "entry > title", text: /#{@subscribed_version.rubygem.name}/
        end
      end
    end

    context "without show dashboard api key scope" do
      setup do
        create(:api_key, key: "12443")

        get :show, params: { api_key: "12443" }, format: "atom"
      end

      should redirect_to("the sign in page") { sign_in_path }
    end
  end

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
          create(:ownership, rubygem: rubygem, user: @user)
          create(:version, rubygem: rubygem)
          rubygem
        end
        get :show
      end

      should respond_with :success
      should "render links" do
        @gems.each do |g|
          assert page.has_content?(g.name)
          selector = "a[href='#{rubygem_path(g)}'][title='#{g.versions.most_recent.info}']"
          assert page.has_selector?(selector)
        end
      end
    end

    context "On GET to show as an atom feed" do
      setup do
        @subscribed_versions = (1..2).map { |n| create(:version, created_at: n.hours.ago) }
        # just to make sure one has a different platform and a summary
        @subscribed_versions << create(:version,
          created_at: 3.hours.ago,
          platform: "win32",
          summary: "&")
        @subscribed_versions.each do |v|
          create(:subscription, rubygem: v.rubygem, user: @user)
        end
        @unsubscribed_versions = (1..3).map do |n|
          create(:version, created_at: n.hours.ago)
        end

        get :show, format: "atom"
      end

      should respond_with :success

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
        assert_select "entry > summary", count: @subscribed_versions.count(&:summary?)
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

    context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
      setup do
        @rubygem = create(:rubygem)
        create(:ownership, rubygem: @rubygem, user: @user)
        GemDownload.increment(
          Rubygem::MFA_REQUIRED_THRESHOLD + 1,
          rubygem_id: @rubygem.id
        )
      end

      context "user has mfa disabled" do
        setup { get :show }
        should redirect_to("the setup mfa page") { new_multifactor_auth_path }
        should "set mfa_redirect_uri" do
          assert_equal dashboard_path, session[:mfa_redirect_uri]
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
          get :show
        end

        should redirect_to("the settings page") { edit_settings_path }
        should "set mfa_redirect_uri" do
          assert_equal dashboard_path, session[:mfa_redirect_uri]
        end
      end

      context "user has MFA set to strong level, expect normal behaviour" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
          get :show
        end

        should "stay on dashboard page without redirecting" do
          assert_response :success
          assert page.has_content? "Dashboard"
        end
      end
    end
  end

  context "On GET to show without being signed in" do
    setup { get :show }

    should redirect_to("the sign in page") { sign_in_path }
  end
end
