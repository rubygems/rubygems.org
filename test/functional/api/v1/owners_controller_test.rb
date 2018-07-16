require 'test_helper'

class Api::V1::OwnersControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "route GET show with #{format.to_s.upcase}" do
      route = { controller: 'api/v1/owners',
                action: 'show',
                rubygem_id: "rails",
                format: format.to_s }
      assert_recognizes(route, "/api/v1/gems/rails/owners.#{format}")
    end

    context "on GET to show with #{format.to_s.upcase}" do
      setup do
        @rubygem = create(:rubygem)
        @user = create(:user)
        @other_user = create(:user)
        @rubygem.ownerships.create(user: @user)

        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        get :show, params: { rubygem_id: @rubygem.to_param }, format: format
      end

      should "return an array" do
        response = yield(@response.body)
        assert_kind_of Array, response
      end

      should "return correct owner email" do
        assert_equal @user.email, yield(@response.body)[0]['email']
      end

      should "return correct owner handle" do
        assert_equal @user.handle, yield(@response.body)[0]['handle']
      end

      should "not return other owner email" do
        assert yield(@response.body).map { |owner| owner['email'] }.exclude?(@other_user.email)
      end
    end
  end

  should_respond_to :json do |body|
    JSON.parse body
  end

  should_respond_to :yaml do |body|
    YAML.safe_load body
  end

  context "on GET to owner gems with handle" do
    setup do
      @user = create(:user)
      get :gems, params: { handle: @user.handle }, format: :json
    end

    should respond_with :success
  end

  context "on GET to owner gems with id" do
    setup do
      @user = create(:user)
      get :gems, params: { handle: @user.id }, format: :json
    end

    should respond_with :success
  end

  should "route POST" do
    route = { controller: 'api/v1/owners',
              action: 'create',
              rubygem_id: "rails",
              format: "json" }
    assert_recognizes(route, path: '/api/v1/gems/rails/owners.json', method: :post)
  end

  context "on POST to owner gem" do
    setup do
      @rubygem = create(:rubygem)
      @user = create(:user)
      @second_user = create(:user)
      @third_user = create(:user)
      @rubygem.ownerships.create(user: @user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "when mfa login-and-write is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_and_write)
      end

      context "on POST to add other user as gem owner with email without OTP" do
        setup do
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :unauthorized
        should "fail to add new owner" do
          refute @rubygem.owners.include?(@second_user)
        end
      end

      context "on POST to add other user as gem owner with email with incorrect OTP" do
        setup do
          @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :unauthorized
        should "fail to add new owner" do
          refute @rubygem.owners.include?(@second_user)
        end
      end

      context "on POST to add other user as gem owner with email with correct OTP" do
        setup do
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :success
        should "succeed to add new owner" do
          assert @rubygem.owners.include?(@second_user)
        end
      end
    end

    context "when mfa login-and-write is disabled" do
      should "add other user as gem owner with email" do
        post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        assert @rubygem.owners.include?(@second_user)
      end

      should "add other user as gem owner with handle" do
        post :create, params: { rubygem_id: @rubygem.to_param, email: @third_user.handle }, format: :json
        assert @rubygem.owners.include?(@third_user)
      end
    end
  end

  should "route DELETE" do
    route = { controller: 'api/v1/owners',
              action: 'destroy',
              rubygem_id: "rails",
              format: "json" }
    assert_recognizes(route, path: '/api/v1/gems/rails/owners.json', method: :delete)
  end

  context "on DELETE to owner gem" do
    setup do
      @rubygem = create(:rubygem)
      @user = create(:user)
      @second_user = create(:user)
      @rubygem.ownerships.create(user: @user)
      @ownership = @rubygem.ownerships.create(user: @second_user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "when mfa login-and-write is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :mfa_login_and_write)
      end

      context "on delete to remove gem owner without OTP" do
        setup do
          delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
        end

        should respond_with :unauthorized
        should "fail to remove gem owner" do
          assert @rubygem.owners.include?(@second_user)
        end
      end

      context "on delete to remove gem owner with incorrect OTP" do
        setup do
          @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
        end

        should respond_with :unauthorized
        should "fail to remove gem owner" do
          assert @rubygem.owners.include?(@second_user)
        end
      end

      context "on delete to remove gem owner with correct OTP" do
        setup do
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
        end

        should respond_with :success
        should "succeed to remove gem owner" do
          refute @rubygem.owners.include?(@second_user)
        end
      end
    end

    context "when mfa login-and-write is disabled" do
      should "remove user as gem owner" do
        delete :destroy,
          params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
        refute @rubygem.owners.include?(@second_user)
      end

      should "not remove last gem owner" do
        @ownership.destroy
        delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @user.email, format: :json }
        assert @rubygem.owners.include?(@user)
        assert_equal 'Unable to remove owner.', @response.body
      end
    end
  end

  should "route GET gems" do
    route = { controller: 'api/v1/owners',
              action: 'gems',
              handle: 'example',
              format: 'json' }
    assert_recognizes(route, path: '/api/v1/owners/example/gems.json', method: :get)
  end

  should "return plain text 404 error" do
    @user = create(:user)
    @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    @request.accept = '*/*'
    post :create, params: { rubygem_id: 'bananas' }
    assert_equal 'This rubygem could not be found.', @response.body
  end
end
