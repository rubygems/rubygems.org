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

        get :show, params: { rubygem_id: @rubygem.to_param }, format: format
      end

      should "return an array" do
        response = yield(@response.body)
        assert_kind_of Array, response
      end

      should "return correct owner handle" do
        assert_equal @user.handle, yield(@response.body)[0]["handle"]
      end

      should "not return other owner handle" do
        assert yield(@response.body).map { |owner| owner["handle"] }.exclude?(@other_user.handle)
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
      assert_equal("Owner could not be found.", @response.body)
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
      assert_equal("Owner could not be found.", @response.body)
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
    context "with add owner api key scope" do
      setup do
        @rubygem = create(:rubygem)
        @user = create(:user)
        @second_user = create(:user)
        @third_user = create(:user)
        @ownership = create(:ownership, rubygem: @rubygem, user: @user)
        @api_key = create(:api_key, key: "12334", add_owner: true, user: @user)
        @request.env["HTTP_AUTHORIZATION"] = "12334"
      end

      context "when mfa for UI and API is enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "adding other user as gem owner without OTP" do
          setup do
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :unauthorized
          should "fail to add new owner" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end

        context "adding other user as gem owner with incorrect OTP" do
          setup do
            @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :unauthorized
          should "fail to add new owner" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end

        context "adding other user as gem owner with correct OTP" do
          setup do
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :success
          should "succeed to add new owner" do
            assert_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end
      end

      context "when mfa for UI only is enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        end

        context "api key has mfa enabled" do
          setup do
            @api_key.mfa = true
            @api_key.save!
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end
          should respond_with :unauthorized
        end

        context "api key does not have mfa enabled" do
          setup do
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end
          should respond_with :success
        end
      end

      context "when mfa for UI and API is disabled" do
        context "add user with email" do
          setup do
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
            Delayed::Worker.new.work_off
          end

          should "add second user as unconfrimed owner" do
            assert_includes @rubygem.owners_including_unconfirmed, @second_user
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
            assert_includes @rubygem.owners_including_unconfirmed, @second_user
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

      context "when mfa is required by gem" do
        setup do
          metadata = { "rubygems_mfa_required" => "true" }
          create(:version, rubygem: @rubygem, number: "1.0.0", metadata: metadata)
        end

        context "api user has enabled mfa" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          end

          should "add other user as gem owner" do
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
            assert_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end

        context "api user has not enabled mfa" do
          setup do
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :forbidden
          should "refuse to add other user as gem owner" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end
      end

      context "when mfa is required by yanked gem" do
        setup do
          metadata = { "rubygems_mfa_required" => "true" }
          create(:version, rubygem: @rubygem, number: "1.0.0", indexed: false, metadata: metadata)

          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :success

        should "add other user as gem owner" do
          assert_includes @rubygem.owners_including_unconfirmed, @second_user
        end
      end

      context "with api key gem scoped" do
        context "to another gem" do
          setup do
            another_rubygem_ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "test"))

            @api_key.update(ownership: another_rubygem_ownership)
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :forbidden
          should "not add other user as gem owner" do
            refute_includes @rubygem.owners, @second_user
          end
        end

        context "to the same gem" do
          setup do
            @api_key.update(rubygem_id: @rubygem.id)
            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :success
          should "adds other user as gem owner" do
            assert_includes @rubygem.owners_including_unconfirmed, @second_user
          end
        end

        context "to a gem with ownership removed" do
          setup do
            @api_key.update(ownership: @ownership)
            @ownership.destroy!

            post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :forbidden
          should "#render_soft_deleted_api_key and display an error" do
            assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
          end
        end
      end

      context "with a soft deleted api key" do
        setup do
          @api_key.soft_delete!

          post :create, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :forbidden
        should "#render_soft_deleted_api_key and display an error" do
          assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
        end
      end

      context "when mfa is recommended" do
        setup do
          User.any_instance.stubs(:mfa_recommended?).returns true
          @emails = [@second_user.email, "doesnot@exist.com", @user.email]
        end

        context "by user with mfa disabled" do
          should "include mfa setup warning" do
            @emails.each do |email|
              post :create, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to set up multi-factor authentication \
                at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_only` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
          end

          should "include change mfa level warning" do
            @emails.each do |email|
              post :create, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to change your multi-factor authentication \
                level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit. \
                Your account will be required to have MFA enabled on one of these levels in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_gem_signin` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          end

          should "not include MFA warnings" do
            @emails.each do |email|
              post :create, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_api` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          end

          should "not include mfa warnings" do
            @emails.each do |email|
              post :create, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end
      end
    end

    context "without add owner api key scope" do
      setup do
        api_key = create(:api_key, key: "12323")
        rubygem = create(:rubygem, owners: [api_key.user])

        @request.env["HTTP_AUTHORIZATION"] = "12323"
        post :create, params: { rubygem_id: rubygem.to_param, email: "some@email.com" }, format: :json
      end

      should respond_with :forbidden
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
    context "with remove owner api key scope" do
      setup do
        @rubygem = create(:rubygem)
        @user = create(:user)
        @second_user = create(:user)
        @ownership = create(:ownership, rubygem: @rubygem, user: @user)
        @ownership = create(:ownership, rubygem: @rubygem, user: @second_user)

        @api_key = create(:api_key, key: "12223", remove_owner: true, user: @user)
        @request.env["HTTP_AUTHORIZATION"] = "12223"
      end

      context "when mfa for UI and API is enabled" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "removing gem owner without OTP" do
          setup do
            delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
          end

          should respond_with :unauthorized
          should "fail to remove gem owner" do
            assert_includes @rubygem.owners, @second_user
          end
        end

        context "removing gem owner with incorrect OTP" do
          setup do
            @request.env["HTTP_OTP"] = (ROTP::TOTP.new(@user.mfa_seed).now.to_i.succ % 1_000_000).to_s
            delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
          end

          should respond_with :unauthorized
          should "fail to remove gem owner" do
            assert_includes @rubygem.owners, @second_user
          end
        end

        context "removing gem owner with correct OTP" do
          setup do
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
            delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
          end

          should respond_with :success
          should "succeed to remove gem owner" do
            refute_includes @rubygem.owners, @second_user
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
            refute_includes @rubygem.owners, @second_user
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
            assert_includes @rubygem.owners, @user
            assert_equal "Unable to remove owner.", @response.body
          end
        end
      end

      context "when mfa is required by gem version" do
        setup do
          metadata = { "rubygems_mfa_required" => "true" }
          create(:version, rubygem: @rubygem, number: "1.0.0", metadata: metadata)
        end

        context "api user hasi not enabled mfa" do
          setup do
            delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
          end

          should respond_with :forbidden
          should "fail to remove gem owner" do
            assert_includes @rubygem.owners, @second_user
          end
        end

        context "api user has enabled mfa" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          end

          context "on delete to remove gem owner with correct OTP" do
            setup do
              @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
              delete :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email, format: :json }
            end

            should respond_with :success
            should "succeed to remove gem owner" do
              refute_includes @rubygem.owners, @second_user
            end
          end
        end
      end

      context "with api key gem scoped" do
        context "to another gem" do
          setup do
            another_rubygem_ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "test"))

            @api_key.update(ownership: another_rubygem_ownership)
            post :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :forbidden
          should "not remove other user as gem owner" do
            assert_includes @rubygem.owners, @second_user
            assert_equal "This API key cannot perform the specified action on this gem.", @response.body
          end
        end

        context "to the same gem" do
          setup do
            @api_key.update(rubygem_id: @rubygem.id)
            post :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :success
          should "removes other user as gem owner" do
            refute_includes @rubygem.owners, @second_user
          end
        end

        context "to a gem with ownership removed" do
          setup do
            @api_key.update(ownership: @ownership)
            @ownership.destroy!

            post :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
          end

          should respond_with :forbidden
          should "#render_soft_deleted_api_key and display an error" do
            assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
          end
        end
      end

      context "with a soft deleted api key" do
        setup do
          @api_key.soft_delete!

          post :destroy, params: { rubygem_id: @rubygem.to_param, email: @second_user.email }, format: :json
        end

        should respond_with :forbidden
        should "#render_soft_deleted_api_key and display an error" do
          assert_equal "An invalid API key cannot be used. Please delete it and create a new one.", @response.body
        end
      end

      context "when mfa is recommended" do
        setup do
          User.any_instance.stubs(:mfa_recommended?).returns true
          @emails = [@second_user.email, "doesnot@exist.com", @user.email, "no@permission.com"]
        end

        context "by user with mfa disabled" do
          should "include mfa setup warning" do
            @emails.each do |email|
              delete :destroy, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to set up multi-factor authentication \
                at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_only` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
          end

          should "include change mfa level warning" do
            @emails.each do |email|
              delete :destroy, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = <<~WARN.chomp


                [WARNING] For protection of your account and gems, we encourage you to change your multi-factor authentication \
                level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit. \
                Your account will be required to have MFA enabled on one of these levels in the future.
              WARN

              assert_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_gem_signin` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          end

          should "not include mfa warnings" do
            @emails.each do |email|
              delete :destroy, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end

        context "by user on `ui_and_api` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
            @request.env["HTTP_OTP"] = ROTP::TOTP.new(@user.mfa_seed).now
          end

          should "not include mfa warnings" do
            @emails.each do |email|
              delete :destroy, params: { rubygem_id: @rubygem.to_param, email: email }, format: :json
              mfa_warning = "[WARNING] For protection of your account and gems"

              refute_includes @response.body, mfa_warning
            end
          end
        end
      end
    end

    context "without remove owner api key scope" do
      setup do
        api_key = create(:api_key, key: "12342")
        rubygem = create(:rubygem, owners: [api_key.user])

        @request.env["HTTP_AUTHORIZATION"] = "12342"
        delete :destroy, params: { rubygem_id: rubygem.to_param, email: "some@owner.com" }, format: :json
      end

      should respond_with :forbidden
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
    create(:api_key, key: "12223", add_owner: true)
    @request.env["HTTP_AUTHORIZATION"] = "12223"
    @request.accept = "*/*"
    post :create, params: { rubygem_id: "bananas" }
    assert_equal "This rubygem could not be found.", @response.body
  end
end
