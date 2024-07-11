require "test_helper"

class Api::V1::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in_as(@user)
  end

  def to_json(body)
    JSON.parse body
  end

  def to_yaml(body)
    YAML.safe_load body
  end

  def response_body
    send(:"to_#{@format}", @response.body)
  end

  def authorize_with(str)
    @request.env["HTTP_AUTHORIZATION"] = "Basic #{Base64.encode64(str)}"
  end

  def assert_mfa_info_included(mfa_level)
    assert response_body.key?("mfa")
    assert_match mfa_level, @response.body
  end

  def refute_mfa_info_included(mfa_level)
    refute response_body.key?("mfa")
    refute_match mfa_level, @response.body
  end

  %i[json yaml].each do |format|
    context "when using #{format}" do
      setup do
        @format = format
      end

      context "on GET to show with id" do
        setup do
          get :show, params: { id: @user.id }, format: format
        end

        should respond_with :success

        should "not return owner mfa information by default" do
          refute_mfa_info_included @user.mfa_level
        end
      end

      context "on GET to show with handle" do
        setup do
          get :show, params: { id: @user.handle }, format: format
        end

        should respond_with :success

        should "hide the user email by default" do
          refute response_body.key?("email")
        end

        should "not return owner mfa information by default" do
          refute_mfa_info_included @user.mfa_level
        end
      end

      context "on GET to me with authentication" do
        setup do
          @user = create(:user)
          authorize_with("#{@user.email}:#{@user.password}")
          get :me, format: format
        end

        should respond_with :success

        should "return owner mfa information" do
          assert_mfa_info_included @user.mfa_level
        end

        context "when mfa is recommended" do
          setup do
            rubygem = create(:rubygem)
            create(:ownership, user: @user, rubygem: rubygem)
            GemDownload.increment(
              Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
              rubygem_id: rubygem.id
            )
            get :me, format: format
          end

          context "when mfa is disabled" do
            should "include warning" do
              expected_warning = I18n.t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp

              assert_includes response_body["warning"].to_s, expected_warning
            end
          end

          context "when mfa is enabled" do
            context "on `ui_only` level" do
              setup do
                @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
                get :me, format: format
              end

              should "include warning" do
                expected_warning = I18n.t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp

                assert_includes response_body["warning"].to_s, expected_warning
              end
            end

            context "on `ui_and_gem_signin` level" do
              setup do
                @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
                get :me, format: format
              end

              should "not include warning in user json" do
                unexpected_warning = "For protection of your account and gems"

                refute_includes response_body["warning"].to_s, unexpected_warning
              end
            end

            context "on `ui_and_api` level" do
              setup do
                @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
                get :me, format: format
              end

              should "not include warning" do
                unexpected_warning = "For protection of your account and gems"

                refute_includes response_body["warning"].to_s, unexpected_warning
              end
            end
          end
        end
      end

      context "on GET to me with bad creds" do
        setup do
          @user = create(:user)
          authorize_with("bad:creds")
          get :me, format: format
        end

        should "deny access" do
          assert_response :unauthorized
          assert_match "Invalid credentials", @response.body
        end
      end

      context "on GET to show when email is public" do
        setup do
          @user.update(public_email: true)
          get :show, params: { id: @user.handle }, format: format
        end

        should respond_with :success

        should "include the user email" do
          assert response_body.key?("email")
          assert_equal @user.email, response_body["email"]
        end

        should "shows the handle" do
          assert_equal @user.handle, response_body["handle"]
        end
      end
    end
  end
end
