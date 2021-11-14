require "test_helper"

class ProfilesControllerTest < ActionController::TestCase
  context "for a user that doesn't exist" do
    should "render not found page" do
      get :show, params: { id: "unknown" }
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

    context "on GET to show when hide email" do
      setup do
        @user.update(hide_email: true)
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

    context "on GET to edit" do
      setup { get :edit }

      should respond_with :success
      should "render user edit page" do
        assert page.has_content? "Edit profile"
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
          @hide_email = true
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update,
            params: { user: { handle: @handle, hide_email: @hide_email, password: @user.password } }
        end

        should respond_with :redirect
        should redirect_to("the profile edit page") { edit_profile_path }
        should set_flash.to("Your profile was updated.")

        should "update email toggle" do
          assert_equal @hide_email, User.last.hide_email
        end
      end

      context "updating without password" do
        setup do
          @user = create(:user, handle: "johndoe")
          sign_in_as(@user)
          put :update, params: { user: { handle: "doejohn" } }
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
            mailer = mock
            mailer.stubs(:deliver)

            Mailer.expects(:email_reset).returns(mailer).times(1)
            Mailer.expects(:email_reset_update).returns(mailer).times(1)
            put :update, params: { user: { unconfirmed_email: @new_email, password: @user.password } }
            Delayed::Worker.new.work_off
          end
        end
      end
    end

    context "on DELETE to destroy" do
      context "correct password" do
        should "enqueue deletion request" do
          assert_difference "Delayed::Job.count", 1 do
            delete :destroy, params: { user: { password: @user.password } }
          end
        end

        context "redirect path and flash" do
          setup do
            delete :destroy, params: { user: { password: @user.password } }
          end

          should redirect_to("the homepage") { root_url }
          should set_flash.to("Your account deletion request has been enqueued."\
                              " We will send you a confirmation mail when your request has been processed.")
        end
      end

      context "incorrect password" do
        should "not enqueue deletion request" do
          assert_no_difference "Delayed::Job.count" do
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
  end

  context "On GET to edit without being signed in" do
    setup { get :edit }
    should redirect_to("the sign in page") { sign_in_path }
  end
end
