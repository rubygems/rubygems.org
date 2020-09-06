require "test_helper"

class Api::V1::OwnersControllerTest < ActionController::TestCase
  def self.should_respond_to(format)
    should "route GET show with #{format.to_s.upcase}" do
      route = { controller: "api/v1/owners",
                action: "show",
                rubygem_id: "rails",
                format: format.to_s }
      assert_recognizes(route, "/api/v1/gems/rails/owners.#{format}")
    end

    context "on GET to show with #{format.to_s.upcase}" do
      setup do
        @rubygem = create(:rubygem)
        @user = create(:user)
        @other_user = create(:user)
        create(:ownership, rubygem: @rubygem, user: @user)

        @request.env["HTTP_AUTHORIZATION"] = @user.api_key
        get :show, params: { rubygem_id: @rubygem.to_param }, format: format
      end

      should "return an array" do
        response = yield(@response.body)
        assert_kind_of Array, response
      end

      should "return correct owner email" do
        assert_equal @user.email, yield(@response.body)[0]["email"]
      end

      should "return correct owner handle" do
        assert_equal @user.handle, yield(@response.body)[0]["handle"]
      end

      should "not return other owner email" do
        assert yield(@response.body).map { |owner| owner["email"] }.exclude?(@other_user.email)
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

  context "on GET to owner gems with nonexistent handle" do
    setup do
      get :gems, params: { handle: "imaginary_handler" }, format: :json
    end

    should "return plaintext with error message" do
      assert_equal @response.body, "Owner could not be found."
    end

    should respond_with :not_found
  end

  context "on GET to owner gems with id" do
    setup do
      @user = create(:user)
      get :gems, params: { handle: @user.id }, format: :json
    end

    should respond_with :success
  end

  context "on GET to owner gems with nonexistent id" do
    setup do
      @user = create(:user)
      get :gems, params: { handle: -9999 }, format: :json
    end

    should "return plain text with error message" do
      assert_equal @response.body, "Owner could not be found."
    end

    should respond_with :not_found
  end

  should "route POST" do
    route = { controller: "api/v1/owners",
              action: "create",
              rubygem_id: "rails",
              format: "json" }
    assert_recognizes(route, path: "/api/v1/gems/rails/owners.json", method: :post)
  end

  context "on POST to owner gem" do
    setup do
      @rubygem = create(:rubygem)
      @user = create(:user)
      @second_user = create(:user)
      create(:ownership, rubygem: @rubygem, user: @user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "when mfa for UI and API is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
      end

      context "on POST to add other user as gem owner without OTP" do
        setup do
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :unauthorized
        should "fail to add new owner" do
          refute @rubygem.owners.include?(@second_user)
        end
      end

      context "on POST to add other user as gem owner with incorrect OTP" do
        setup do
          @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :unauthorized
        should "fail to add new owner" do
          refute @rubygem.owners.include?(@second_user)
        end
      end

      context "on POST to add other user as gem owner with correct OTP" do
        setup do
          @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :success
        should "succeed to add new owner" do
          assert @rubygem.owners_including_unconfirmed.include?(@second_user)
        end
      end
    end

    context "when mfa for UI and API is disabled" do
      context "add user with email" do
        setup do
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          Delayed::Worker.new.work_off
        end

        should "add second user as unconfrimed owner" do
          assert @rubygem.owners_including_unconfirmed.include?(@second_user)
          assert_equal "#{@second_user.handle} was added as an unconfirmed owner. "\
            "Ownership access will be enabled after the user clicks on the confirmation mail sent to their email.", @response.body
        end

        should "send confirmation mail to second user" do
          assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
          assert_equal [@second_user.email], last_email.to
        end
      end

      context "add user with handler" do
        setup do
          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.handle }, format: :json
        end

        should "add other user as gem owner" do
          assert @rubygem.owners_including_unconfirmed.include?(@second_user)
        end
      end
    end

    context "user is not found" do
      setup do
        post :create, params: { rubygem_id: @rubygem.to_param, email: "doesnot@exist.com" }
      end

      should respond_with :not_found
    end

    context "owner already exists" do
      setup do
        post :create, params: { rubygem_id: @rubygem.to_param, email: @user.email }
      end

      should respond_with :unprocessable_entity
      should "respond with error message" do
        assert_equal "User has already been taken", @response.body
      end
    end
  end

  should "route DELETE" do
    route = { controller: "api/v1/owners",
              action: "destroy",
              rubygem_id: "rails",
              format: "json" }
    assert_recognizes(route, path: "/api/v1/gems/rails/owners.json", method: :delete)
  end

  context "on DELETE to owner gem" do
    setup do
      @rubygem = create(:rubygem)
      @user = create(:user)
      @second_user = create(:user)
      create(:ownership, rubygem: @rubygem, user: @user)
      @ownership = create(:ownership, rubygem: @rubygem, user: @second_user)
      @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    end

    context "when mfa for UI and API is enabled" do
      setup do
        @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
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

    context "when mfa for UI and API is disabled" do
      context "user is not the only confirmed owner" do
        setup do
          delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
          Delayed::Worker.new.work_off
        end

        should "remove user as gem owner" do
          refute @rubygem.owners.include?(@second_user)
          assert_equal "Owner removed successfully.", @response.body
        end

        should "send email notification to user being removed" do
          assert_equal "You were removed as an owner from #{@rubygem.name} gem", last_email.subject
          assert_equal [@second_user.email], last_email.to
        end
      end

      context "user is the only confirmed owner" do
        setup do
          @ownership.destroy
          delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @user.email, format: :json }
        end

        should "not remove last gem owner" do
          assert @rubygem.owners.include?(@user)
          assert_equal "Unable to remove owner.", @response.body
        end
      end
    end
  end

  should "route GET gems" do
    route = { controller: "api/v1/owners",
              action: "gems",
              handle: "example",
              format: "json" }
    assert_recognizes(route, path: "/api/v1/owners/example/gems.json", method: :get)
  end

  should "return plain text 404 error" do
    @user = create(:user)
    @request.env["HTTP_AUTHORIZATION"] = @user.api_key
    @request.accept = "*/*"
    post :create, params: { rubygem_id: "bananas" }
    assert_equal "This rubygem could not be found.", @response.body
  end
end
