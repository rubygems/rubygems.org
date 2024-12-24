require "test_helper"

class ProfilesControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  context "for a user that doesn't exist" do
    should "render not found page" do
      get :show, params: { id: "unknown" }

      assert_response :not_found
    end
  end

  context "for a user whose email is not confirmed" do
    setup do
      @user = create(:user)
      @user.update(email_confirmed: false)
    end

    should "render not found page" do
      get :show, params: { id: @user.handle }

      assert_response :not_found
    end
  end

  context "when not logged in" do
    setup { @user = create(:user) }

    context "on GET to show with id" do
      setup { get :show, params: { id: @user.id } }

      should respond_with :success

      should "not render Email link by defaulr" do
        refute page.has_selector?("a[href='mailto:#{@user.email}']")
      end
    end

    context "on GET to me" do
      setup { get :me }

      should respond_with :redirect
      should redirect_to("the sign in path") { sign_in_path }
    end

    context "on GET to security_events" do
      setup { get :security_events }

      should respond_with :redirect
      should redirect_to("the sign in path") { sign_in_path }
    end

    context "on GET to show when hide email" do
      setup do
        @user.update(public_email: false)
        get :show, params: { id: @user.id }
      end

      should respond_with :success
      should "not render Email link" do
        refute page.has_content?("Email Me")
        refute page.has_selector?("a[href='mailto:#{@user.email}']")
      end
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on GET to show" do
      setup do
        @rubygems = (0..10).map do |n|
          create(:rubygem, downloads: n * 100).tap do |rubygem|
            create(:ownership, rubygem: rubygem, user: @user)
            create(:version, rubygem: rubygem)
          end
        end.reverse

        get :show, params: { id: @user.handle }
      end

      should respond_with :success
      should "display all gems of user" do
        11.times { |i| assert page.has_content? @rubygems[i].name }
      end
    end

    context "on GET to show with handle" do
      setup do
        get :show, params: { id: @user.handle }
      end

      should respond_with :success

      should "render user show page" do
        assert page.has_content? @user.handle
      end
    end

    context "on GET to me" do
      setup do
        get :me
      end

      should respond_with :redirect
      should redirect_to("the user's profile page") { profile_path(@user.handle) }
    end

    context "on GET to delete" do
      setup do
        get :delete
      end

      should respond_with :success

      should "render user delete page" do
        assert_text "Delete profile"
        assert_selector "input[type=password][autocomplete=current-password]"
      end
    end

    context "on GET to edit" do
      setup { get :edit }

      should respond_with :success

      should "render user edit page" do
        assert page.has_content? "Edit profile"
        assert page.has_css? "input[type=password][autocomplete=current-password]"
      end
    end

    context "on PUT to update" do
      context "updating handle" do
        setup do
          @handle = "john_m_doe"
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update, params: { user: { handle: @handle, password: @user.password } }
        end

        should respond_with :redirect
        should redirect_to("the profile edit page") { edit_profile_path }
        should set_flash.to("Your profile was updated.")

        should "update handle" do
          assert_equal @handle, User.last.handle
        end
      end

      context "updating show email" do
        setup do
          @handle = "john_m_doe"
          @public_email = true
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update,
            params: { user: { handle: @handle, public_email: @public_email, password: @user.password } }
        end

        should respond_with :redirect
        should redirect_to("the profile edit page") { edit_profile_path }
        should set_flash.to("Your profile was updated.")

        should "update email toggle" do
          assert_equal @public_email, User.last.public_email
        end
      end

      context "updating without params" do
        setup do
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update, params: {}
        end

        should respond_with :bad_request
      end

      context "updating with missing password params" do
        setup do
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update, params: { user: { handle: "doejohn" } }
        end

        should respond_with :bad_request
      end

      context "updating without inputting password" do
        setup do
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update, params: { user: { handle: "doejohn", password: "" } }
        end

        should set_flash.to("This request was denied. We could not verify your password.")
        should redirect_to("the profile edit page") { edit_profile_path }

        should "not update handle" do
          assert_equal "johndoe", @user.handle
        end
      end

      context "updating with old format password" do
        setup do
          @handle = "updated_user"
          @user = build(:user, handle: "old_user", password: "old")
          @user.save(validate: false)
          sign_in_as(@user)
          put :update, params: { user: { handle: @handle, password: @user.password } }
        end

        should respond_with :redirect

        should "update handle" do
          assert_equal @handle, @user.handle
        end
      end

      context "updating email with existing email" do
        setup do
          create(:user, email: "cannotchange@tothis.com")
          put :update, params: { user: { unconfirmed_email: "cannotchange@tothis.com", password: @user.password } }
        end

        should "not set unconfirmed_email" do
          assert page.has_content? "Email address has already been taken"
          refute_equal "cannotchange@tothis.com", @user.unconfirmed_email
        end
      end

      context "updating email with existing unconfirmed_email" do
        setup do
          create(:user, unconfirmed_email: "cannotchange@tothis.com")
          put :update, params: { user: { unconfirmed_email: "cannotchange@tothis.com", password: @user.password } }
        end

        should "set unconfirmed_email" do
          assert_equal "cannotchange@tothis.com", @user.unconfirmed_email
        end
      end

      context "updating email" do
        context "yet to verify the updated email" do
          setup do
            @current_email = "john@doe.com"
            @user = create(:user, email: @current_email)
            sign_in_as(@user)
            @new_email = "change@tothis.com"
          end

          should "set unconfirmed email and confirmation token" do
            put :update, params: { user: { unconfirmed_email: @new_email, password: @user.password } }

            assert_equal @new_email, @user.unconfirmed_email
            assert @user.confirmation_token
          end

          should "not update the current email" do
            put :update, params: { user: { unconfirmed_email: @new_email, password: @user.password } }

            assert_equal @current_email, @user.email
          end

          should "send email reset mails to new and current email addresses" do
            assert_enqueued_email_with Mailer, :email_reset, args: [@user] do
              assert_enqueued_email_with Mailer, :email_reset_update, args: [@user] do
                put :update, params: { user: { unconfirmed_email: @new_email, password: @user.password } }
              end
            end
          end
        end
      end
    end

    context "on DELETE to destroy" do
      context "correct password" do
        should "enqueue deletion request" do
          assert_enqueued_jobs 1, only: DeleteUserJob do
            delete :destroy, params: { user: { password: @user.password } }
          end
        end

        context "redirect path and flash" do
          setup do
            delete :destroy, params: { user: { password: @user.password } }
          end

          should redirect_to("the homepage") { root_url }
          should set_flash.to("Your account deletion request has been enqueued. " \
                              "We will send you a confirmation mail when your request has been processed.")
        end
      end

      context "incorrect password" do
        should "not enqueue deletion request" do
          assert_enqueued_jobs 0 do
            post :destroy, params: { user: { password: "youshallnotpass" } }
          end
        end

        context "redirect path and flash" do
          setup do
            delete :destroy, params: { user: { password: "youshallnotpass" } }
          end

          should redirect_to("the profile edit page") { edit_profile_path }
          should set_flash.to("This request was denied. We could not verify your password.")
        end
      end
    end

    context "on GET to security_events" do
      setup do
        create(:events_user_event, user: @user, tag: Events::UserEvent::LOGIN_SUCCESS)
        create(:events_user_event, user: @user, tag: Events::UserEvent::LOGIN_SUCCESS, additional: { authentication_method: "webauthn" })
        create(:events_user_event, user: @user, tag: Events::UserEvent::LOGIN_SUCCESS, additional: { two_factor_method: "webauthn" })
        create(:events_user_event, user: @user, tag: Events::UserEvent::LOGIN_SUCCESS, additional: { two_factor_method: "OTP" })

        create(:events_user_event, user: @user, tag: Events::UserEvent::EMAIL_SENT)

        create(:events_user_event, user: @user, tag: Events::UserEvent::EMAIL_ADDED, additional: { email: "other@example.com" })
        create(:events_user_event, user: @user, tag: Events::UserEvent::EMAIL_VERIFIED, additional: { email: "other@example.com" })

        create(:events_user_event, user: @user, tag: Events::UserEvent::API_KEY_CREATED, additional: { gem: create(:rubygem).name })
        create(:events_user_event, user: @user, tag: Events::UserEvent::API_KEY_DELETED)
        create(:events_user_event, user: @user, tag: Events::UserEvent::PASSWORD_CHANGED)

        get :security_events
      end

      should respond_with :success
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

      redirect_scenarios = {
        "GET to delete" => { action: :delete, request: { method: "GET", params: { id: 1 } }, path: "/profile/delete" },
        "DELETE to destroy" => { action: :destroy, request: { method: "DELETE", params: { id: 1 } }, path: "/profile" },
        "GET to edit" => { action: :edit, request: { method: "GET", params: { id: 1 } }, path: "/profile/edit" },
        "PATCH to update" => { action: :update, request: { method: "PATCH", params: { id: 1 } }, path: "/profile" },
        "PUT to update" => { action: :update, request: { method: "PUT", params: { id: 1 } }, path: "/profile" }
      }

      context "user has mfa disabled" do
        context "on GET to show" do
          setup { get :show, params: { id: @user.id } }

          should "not redirect to mfa" do
            assert_response :success
            assert page.has_content? "Edit Profile"
          end
        end

        redirect_scenarios.each do |label, request_params|
          context "on #{label}" do
            setup { process(request_params[:action], **request_params[:request]) }

            should redirect_to("the edit settings page") { edit_settings_path }

            should "set mfa_redirect_uri" do
              assert_equal request_params[:path], @controller.session[:mfa_redirect_uri]
            end
          end
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        end

        context "on GET to show" do
          setup { get :show, params: { id: @user.id } }

          should "not redirect to mfa" do
            assert_response :success
            assert page.has_content? "Edit Profile"
          end
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
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "on GET to show" do
          setup { get :show, params: { id: @user.id } }

          should "not redirect to mfa" do
            assert_response :success
            assert page.has_content? "Edit Profile"
          end
        end
      end
    end
  end

  context "On GET to edit without being signed in" do
    setup { get :edit }
    should redirect_to("the sign in page") { sign_in_path }
  end
end
