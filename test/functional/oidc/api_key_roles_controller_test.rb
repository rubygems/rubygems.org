require "test_helper"

class OIDC::ApiKeyRolesControllerTest < ActionController::TestCase
  context "when not logged in" do
    setup { @user = create(:user) }

    context "on GET to index" do
      setup { get :index }

      should redirect_to("sign in") { sign_in_path }
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      @api_key_role = create(:oidc_api_key_role, user: @user)
      @id_token = create(:oidc_id_token, api_key_role: @api_key_role)
      sign_in_as(@user)
    end

    context "with a password session" do
      setup do
        session[:verification] = 10.minutes.from_now
        session[:verified_user] = @user.id
      end

      context "on GET to index" do
        setup { get :index }
        should respond_with :success
      end

      context "on GET to show with id" do
        setup { get :show, params: { token: @api_key_role.token } }
        should respond_with :success
      end

      context "on GET to show with nonexistent id" do
        setup { get :show, params: { token: "DNE" } }
        should respond_with :not_found
      end
    end

    context "without a password session" do
      context "on GET to index" do
        setup { get :index }
        should redirect_to("verify session") { verify_session_path }
      end

      context "on GET to show with id" do
        setup { get :show, params: { token: @api_key_role.token } }
        should redirect_to("verify session") { verify_session_path }
      end

      context "on GET to show with nonexistent id" do
        setup { get :show, params: { token: "DNE" } }
        should redirect_to("verify session") { verify_session_path }
      end
    end
  end
end
