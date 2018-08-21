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

        context "on showing with MFA set to UI only" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_mfa_only)
            get :show, format: format
          end

          should respond_with :success
          should "return right mfa level" do
            result = if format == :plain
                       @response.body
                     else
                       parse(format, @response.body)['mfa_level']
                     end
            assert result == 'ui_mfa_only'
          end
        end

        context "on showing with MFA set to UI and API" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api_mfa)
            get :show, format: format
          end

          should respond_with :success
          should "return right mfa level" do
            result = if format == :plain
                       @response.body
                     else
                       parse(format, @response.body)['mfa_level']
                     end
            assert result == 'ui_and_api_mfa'
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
