require "test_helper"

class NotifiersControllerTest < ActionController::TestCase
  context "when not logged in" do
    setup do
      @user = create(:user)
      get :show
    end
    should redirect_to("the sign in page") { sign_in_path }
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
      setup do
        @rubygem = create(:rubygem)
        @ownership = create(:ownership, rubygem: @rubygem, user: @user)
        GemDownload.increment(
          Rubygem::MFA_REQUIRED_THRESHOLD + 1,
          rubygem_id: @rubygem.id
        )
      end

      redirect_scenarios = {
        "GET to show" => { action: :show, request: { method: "GET" }, path: "/notifier" },
        "PATCH to update" => { action: :update, request: { method: "PATCH", params: { ownerships: { 1 => { push: "off" } } } }, path: "/notifier" },
        "PUT to update" => { action: :update, request: { method: "PUT", params: { ownerships: { 1 => { push: "off" } } } }, path: "/notifier" }
      }

      context "user has mfa disabled" do
        redirect_scenarios.each do |label, request_params|
          context "on #{label}" do
            setup { process(request_params[:action], **request_params[:request]) }

            should redirect_to("the setup mfa page") { new_multifactor_auth_path }
            should "set mfa_redirect_uri" do
              assert_equal request_params[:path], @controller.session[:mfa_redirect_uri]
            end
          end
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        end

        redirect_scenarios.each do |label, request_params|
          context "on #{label}" do
            setup { process(request_params[:action], **request_params[:request]) }

            should redirect_to("the settings page") { edit_settings_path }
            should "set mfa_redirect_uri" do
              assert_equal request_params[:path], @controller.session[:mfa_redirect_uri]
            end
          end
        end
      end

      context "user has MFA set to strong level, expect normal behaviour" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "on GET to show" do
          setup do
            get :show
          end

          should "stay on notifiers page without redirecting" do
            assert_response :success
            assert page.has_content? "Email notifications"
          end
        end

        context "on PATCH to update" do
          setup do
            patch :update, params: { ownerships: { @ownership.id => { push: "off" } } }
          end

          should redirect_to("the notifier page") { notifier_path }
        end

        context "on PUT to update" do
          setup do
            put :update, params: { ownerships: { @ownership.id => { push: "off" } } }
          end

          should redirect_to("the notifier page") { notifier_path }
        end
      end
    end
  end
end
