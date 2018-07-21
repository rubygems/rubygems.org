require 'test_helper'

class Api::V1::MultifactorAuthsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    @second_user = create(:user)
  end

  def parse(type, content)
    case type
    when :json then JSON.parse(content)
    when :yaml then YAML.safe_load(content)
    else content
    end
  end

  %i[json yaml plain].each do |format|
    context "when using #{format}" do
      context "on showing own MFA status" do
        setup do
          @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        end

        context "on showing with MFA disabled" do
          setup do
            get :show, format: format
          end

          should respond_with :success
          should "return right mfa level" do
            result = if format == :plain
                       @response.body
                     else
                       parse(format, @response.body)['mfa_level']
                     end
            assert result == 'no_mfa'
          end
        end

        context "on showing with MFA set to login only" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_only)
            get :show, format: format
          end

          should respond_with :success
          should "return right mfa level" do
            result = if format == :plain
                       @response.body
                     else
                       parse(format, @response.body)['mfa_level']
                     end
            assert result == 'mfa_login_only'
          end
        end

        context "on showing with MFA set to login and write" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_and_write)
            get :show, format: format
          end

          should respond_with :success
          should "return right mfa level" do
            result = if format == :plain
                       @response.body
                     else
                       parse(format, @response.body)['mfa_level']
                     end
            assert result == 'mfa_login_and_write'
          end
        end
      end
    end
  end

  context "when no api key provided" do
    setup do
      get :show
    end

    should respond_with :unauthorized
  end
end
