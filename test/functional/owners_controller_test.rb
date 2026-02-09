require "test_helper"

class OwnersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "When logged in and verified" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: @rubygem)
      verified_sign_in_as(@user)
    end

    teardown do
      session[:verification] = nil
      session[:verified_user] = nil
    end

    context "on GET to index" do
      context "when user owns the gem" do
        setup do
          unconfirmed_owner = create(:user)
          create(:ownership, :unconfirmed, user: unconfirmed_owner, rubygem: @rubygem)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :success
        should "render gem owners including unconfirmed in owners table" do
          @rubygem.ownerships_including_unconfirmed.each do |o|
            assert page.has_content?(o.owner_name)
          end
        end
      end

      context "when user is a maintainer of the gem" do
        setup do
          @maintainer = create(:user)
          create(:ownership, user: @maintainer, rubygem: @rubygem, role: :maintainer)
          verified_sign_in_as(@maintainer)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :success
        should "render gem owners in owners table" do
          @rubygem.ownerships_including_unconfirmed.each do |o|
            assert page.has_content?(o.owner_name)
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          verified_sign_in_as(@other_user)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }
        should set_flash[:alert].to "Forbidden"
      end
    end

    context "on POST to create ownership" do
      context "when user is a maintainer of the gem" do
        setup do
          @maintainer = create(:user)
          create(:ownership, user: @maintainer, rubygem: @rubygem, role: :maintainer)
          verified_sign_in_as(@maintainer)
          @new_owner = create(:user)
          post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name, role: :owner }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }
        should set_flash[:alert].to "Forbidden"

        should "not add other user as owner" do
          refute_includes @rubygem.owners_including_unconfirmed, @new_owner
        end
      end

      context "when user owns the gem" do
        context "with invalid handle" do
          setup do
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              post :create, params: { handle: "no_user", rubygem_id: @rubygem.name, role: :owner }
            end
          end

          should respond_with :unprocessable_content

          should "show error message" do
            expected_alert = "User must exist"

            assert_equal expected_alert, flash[:alert]
          end

          should "not send confirmation email" do
            assert_emails 0
          end
        end

        context "with valid handle" do
          setup do
            @new_owner = create(:user)
            post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name, role: :owner }
          end

          should redirect_to("ownerships index") { rubygem_owners_path(@rubygem.slug) }
          should "add unconfirmed ownership record" do
            assert_includes @rubygem.owners_including_unconfirmed, @new_owner
            assert_nil @rubygem.ownerships_including_unconfirmed.find_by(user: @new_owner).confirmed_at
          end
          should "set success notice flash" do
            expected_notice = "#{@new_owner.handle} was added as an unconfirmed owner. " \
                              "Ownership access will be enabled after the user clicks on the confirmation mail sent to their email."

            assert_equal expected_notice, flash[:notice]
          end
          should "send confirmation email" do
            assert_enqueued_emails 1
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob

            assert_emails 1
            assert_equal "Please confirm the ownership of the #{@rubygem.name} gem on RubyGems.org", last_email.subject
            assert_equal [@new_owner.email], last_email.to
          end

          context "when ownership was deleted before running mailer job" do
            setup { @rubygem.owners_including_unconfirmed.last.destroy }

            should "not send confirmation email" do
              assert_raises(ActiveJob::DeserializationError) do
                perform_enqueued_jobs only: ActionMailer::MailDeliveryJob
              end
              assert_emails 0
            end
          end
        end

        context "when the gem has mfa requirement" do
          setup do
            metadata = { "rubygems_mfa_required" => "true" }
            create(:version, rubygem: @rubygem, number: "0.1.0", metadata: metadata)

            @new_owner = create(:user)
          end

          context "owner has not enabled mfa" do
            setup do
              post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name }
            end

            should respond_with :forbidden

            should "show error message" do
              expected_alert = "The gem has MFA requirement enabled, please setup MFA on your account."

              assert_equal expected_alert, flash[:alert]
            end
          end

          context "owner has enabled mfa" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
              post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name, role: :owner }
            end

            should redirect_to("ownerships index") { rubygem_owners_path(@rubygem.slug) }

            should "set success notice flash" do
              expected_notice = "#{@new_owner.handle} was added as an unconfirmed owner. " \
                                "Ownership access will be enabled after the user clicks on the confirmation mail sent to their email."

              assert_equal expected_notice, flash[:notice]
            end
          end

          context "with invalid role" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
              post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name, role: :invalid }
            end

            should render_template :index

            should "set alert notice flash" do
              assert_equal "Role is not included in the list", flash[:alert]
            end
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          verified_sign_in_as(@other_user)
          post :create, params: { handle: @other_user.display_id, rubygem_id: @rubygem.name }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }
        should set_flash[:alert].to "Forbidden"

        should "not add other user as owner" do
          refute_includes @rubygem.owners_including_unconfirmed, @other_user
        end
      end
    end

    context "on DELETE to owners" do
      context "when user is a maintainer of the gem" do
        setup do
          @maintainer = create(:user)
          create(:ownership, user: @maintainer, rubygem: @rubygem, role: :maintainer)
          verified_sign_in_as(@maintainer)
          @second_user = create(:user)
          create(:ownership, rubygem: @rubygem, user: @second_user)
          delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }

        should "not remove user as owner" do
          assert_includes @rubygem.owners, @second_user
        end
      end

      context "when user owns the gem" do
        context "with invalid handle" do
          setup do
            delete :destroy, params: { rubygem_id: @rubygem.name, handle: "no_handle" }
          end
          should respond_with :not_found
        end

        context "with handle of confirmed owner" do
          setup do
            @second_user = create(:user)
            @ownership = create(:ownership, rubygem: @rubygem, user: @second_user)
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
            end
          end

          should redirect_to("ownership index") { rubygem_owners_path(@rubygem.slug) }

          should "remove the ownership record" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
          should "send email notifications about owner removal" do
            assert_emails 1
            assert_contains last_email.subject, "You were removed as an owner from the #{@rubygem.name} gem"
            assert_equal [@second_user.email], last_email.to
          end
        end

        context "with handle of unconfirmed owner" do
          setup do
            @second_user = create(:user)
            @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @second_user)
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
            end
          end
          should redirect_to("ownership index") { rubygem_owners_path(@rubygem.slug) }

          should "remove the ownership record" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
          should "send email notifications about owner removal" do
            assert_emails 1
            assert_contains last_email.subject, "You were removed as an owner from the #{@rubygem.name} gem"
            assert_equal [@second_user.email], last_email.to
          end
        end

        context "with handle of last owner" do
          setup do
            @last_owner = @rubygem.owners.last
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              delete :destroy, params: { rubygem_id: @rubygem.name, handle: @last_owner.display_id }
            end
          end
          should set_flash.now[:alert].to "Can't remove the only owner of the gem"

          should "not remove the ownership record" do
            assert_includes @rubygem.owners_including_unconfirmed, @last_owner
            assert_emails 0
          end
        end

        context "when the gem has mfa requirement" do
          setup do
            @second_user = create(:user)
            create(:ownership, :unconfirmed, rubygem: @rubygem, user: @second_user)

            metadata = { "rubygems_mfa_required" => "true" }
            create(:version, rubygem: @rubygem, number: "0.1.0", metadata: metadata)
          end

          context "owner has not enabled mfa" do
            setup do
              delete :destroy, params: { handle: @second_user.display_id, rubygem_id: @rubygem.name }
            end

            should respond_with :forbidden

            should "show error message" do
              expected_alert = "The gem has MFA requirement enabled, please setup MFA on your account."

              assert_equal expected_alert, flash[:alert]
            end
          end

          context "owner has enabled mfa" do
            setup do
              @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
              delete :destroy, params: { handle: @second_user.display_id, rubygem_id: @rubygem.name }
            end

            should redirect_to("ownerships index") { rubygem_owners_path(@rubygem.slug) }

            should "set success notice flash" do
              expected_notice = "#{@second_user.handle} was removed from the owners successfully"

              assert_equal expected_notice, flash[:notice]
            end
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          verified_sign_in_as(@other_user)

          @last_owner = @rubygem.owners.last
          delete :destroy, params: { rubygem_id: @rubygem.name, handle: @last_owner.display_id }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }

        should "not remove user as owner" do
          assert_includes @rubygem.owners, @last_owner
        end
      end
    end

    context "on GET to resend confirmation" do
      setup do
        @new_owner = create(:user)
        verified_sign_in_as(@new_owner)
      end

      context "when unconfirmed ownership exists" do
        setup do
          create(:ownership, :unconfirmed, rubygem: @rubygem, user: @new_owner)
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            get :resend_confirmation, params: { rubygem_id: @rubygem.name }
          end
        end

        should redirect_to("rubygem show") { rubygem_path(@rubygem.slug) }
        should "set success notice flash" do
          success_flash = "A confirmation mail has been re-sent to your email"

          assert_equal success_flash, flash[:notice]
        end
        should "resend confirmation email" do
          assert_emails 1
          assert_equal "Please confirm the ownership of the #{@rubygem.name} gem on RubyGems.org", last_email.subject
          assert_equal [@new_owner.email], last_email.to
        end
      end

      context "when ownership doesn't exist" do
        setup do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            get :resend_confirmation, params: { rubygem_id: @rubygem.name }
          end
        end

        should respond_with :not_found

        should "not resend confirmation email" do
          assert_emails 0
        end
      end

      context "when confirmed ownership exists" do
        setup do
          create(:ownership, rubygem: @rubygem, user: @new_owner)
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            get :resend_confirmation, params: { rubygem_id: @rubygem.name }
          end
        end

        should respond_with :not_found

        should "not resend confirmation email" do
          assert_emails 0
        end
      end
    end

    context "on GET edit ownership" do
      setup do
        @owner = create(:user)
        @maintainer = create(:user)
        @rubygem = create(:rubygem, owners: [@owner, @maintainer])

        verified_sign_in_as(@owner)
      end

      context "when editing another owner's role" do
        setup do
          get :edit, params: { rubygem_id: @rubygem.name, handle: @maintainer.display_id }
        end

        should respond_with :success
        should render_template :edit
      end

      context "when editing your own role" do
        setup do
          get :edit, params: { rubygem_id: @rubygem.name, handle: @owner.display_id }
        end

        should redirect_to("gem info page") { rubygem_path(@rubygem.slug) }
        should set_flash[:alert].to "Can't update your own Role"
      end
    end

    context "on PATCH to update ownership" do
      setup do
        @owner = create(:user)
        @maintainer = create(:user)
        @rubygem = create(:rubygem, owners: [@owner, @maintainer])

        verified_sign_in_as(@owner)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @maintainer.display_id, role: :maintainer }
      end

      should redirect_to("rubygem show") { rubygem_owners_path(@rubygem.slug) }

      should "set success notice flash" do
        assert_equal "#{@maintainer.name} was successfully updated.", flash[:notice]
      end

      should "downgrade the ownership to a maintainer role" do
        ownership = Ownership.find_by(rubygem: @rubygem, user: @maintainer)

        assert_predicate ownership, :maintainer?
        assert_enqueued_email_with OwnersMailer, :owner_updated, params: { ownership: ownership, authorizer: @owner }
      end
    end

    context "when updating ownership without role" do
      setup do
        @owner = create(:user)
        @maintainer = create(:user)
        @rubygem = create(:rubygem, owners: [@owner, @maintainer])

        verified_sign_in_as(@owner)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @maintainer.display_id }
      end

      should redirect_to("ownerships index") { rubygem_owners_path(@rubygem.slug) }

      should "not update the role" do
        ownership = Ownership.find_by(rubygem: @rubygem, user: @maintainer)

        assert_predicate ownership, :owner?
      end
    end

    context "when updating ownership with invalid role" do
      setup do
        @owner = create(:user)
        @maintainer = create(:user)
        @rubygem = create(:rubygem, owners: [@owner, @maintainer])

        verified_sign_in_as(@owner)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @maintainer.display_id, role: :invalid }
      end

      should respond_with :unprocessable_content

      should "set error flash message" do
        assert_equal "Role is not included in the list", flash[:alert]
      end
    end

    context "when updating the role of currently signed in user" do
      setup do
        @owner = create(:user)
        @rubygem = create(:rubygem)
        @ownership = create(:ownership, user: @owner, rubygem: @rubygem, role: :owner)

        verified_sign_in_as(@owner)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @owner.display_id, role: :maintainer }
      end

      should "not update the ownership of the current user" do
        assert_predicate @ownership.reload, :owner?
      end

      should "set notice flash message" do
        assert_equal "Can't update your own Role", flash[:alert]
      end
    end
  end

  context "when logged in and unverified" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: @rubygem)
      sign_in_as(@user)
    end

    context "on GET to index" do
      setup do
        get :index, params: { rubygem_id: @rubygem.name }
      end

      should redirect_to("sessions#verify") { verify_session_path }
      should use_before_action(:redirect_to_verify)
    end

    context "on POST to create ownership" do
      setup do
        @new_owner = create(:user)
        post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name, role: :owner }
      end

      should redirect_to("sessions#verify") { verify_session_path }
      should use_before_action(:redirect_to_verify)

      should "not add unconfirmed ownership record" do
        refute_includes @rubygem.owners_including_unconfirmed, @new_owner
      end
    end

    context "on DELETE to owners" do
      setup do
        @second_user = create(:user)
        @ownership = create(:ownership, rubygem: @rubygem, user: @second_user)
        delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
      end
      should redirect_to("sessions#verify") { verify_session_path }
      should use_before_action(:redirect_to_verify)

      should "not remove the ownership record" do
        assert_includes @rubygem.owners, @second_user
      end
    end

    context "on GET to edit" do
      setup do
        @second_user = create(:user)
        @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @second_user)
        get :edit, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
      end

      should redirect_to("sessions#verify") { verify_session_path }
      should use_before_action(:redirect_to_verify)
    end

    context "on PATCH to update" do
      setup do
        @second_user = create(:user)
        @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @second_user, role: :owner)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id, role: :maintainer }
      end

      should redirect_to("sessions#verify") { verify_session_path }
      should use_before_action(:redirect_to_verify)
    end
  end

  context "When user not logged in" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
    end

    context "on GET to confirm" do
      setup do
        create(:ownership, rubygem: @rubygem)
        @ownership = create(:ownership, :unconfirmed, user: @user, rubygem: @rubygem)
      end

      context "when token has not expired" do
        setup do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          end
          @ownership.reload
        end

        should "confirm ownership" do
          assert_predicate @ownership, :confirmed?
          assert redirect_to("rubygem show") { rubygem_path(@rubygem.slug) }
          assert_equal "You were added as an owner to the #{@rubygem.name} gem", flash[:notice]
        end

        should "not sign in the user" do
          refute_predicate @controller.request.env[:clearance], :signed_in?
        end

        should "send email notifications about new owner" do
          owner_added_email_subjects = ActionMailer::Base.deliveries.map(&:subject)

          assert_contains owner_added_email_subjects, "You were added as an owner to the #{@rubygem.name} gem"
          assert_contains owner_added_email_subjects, "User #{@user.handle} was added as an owner to the #{@rubygem.name} gem"

          owner_added_email_to = ActionMailer::Base.deliveries.map(&:to).flatten

          assert_same_elements @rubygem.owners.map(&:email), owner_added_email_to
        end
      end

      context "when token has expired" do
        setup do
          travel_to 3.days.from_now
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          end
        end

        should "warn about invalid token" do
          assert respond_with :success
          assert_equal "The confirmation token has expired. Please try resending the token from the gem page.", flash[:alert]
          assert_predicate @ownership, :unconfirmed?
        end

        should "not send email notification about owner added" do
          assert_emails 0
        end
      end
    end

    context "on GET to index" do
      setup do
        get :index, params: { rubygem_id: @rubygem.name }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on POST to add owners" do
      setup do
        new_owner = create(:user)
        post :create, params: { handle: new_owner.display_id, rubygem_id: @rubygem.name }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on DELETE to remove owner" do
      setup do
        create(:ownership, rubygem: @rubygem, user: @user)
        delete :destroy, params: { rubygem_id: @rubygem.name, handle: @user.display_id }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on EDIT to update owner" do
      setup do
        create(:ownership, rubygem: @rubygem, user: @user)
        get :edit, params: { rubygem_id: @rubygem.name, handle: @user.display_id }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end

    context "on PATCH to update owner" do
      setup do
        create(:ownership, rubygem: @rubygem, user: @user)
        patch :update, params: { rubygem_id: @rubygem.name, handle: @user.display_id, role: :owner }
      end

      should "redirect to sign in path" do
        assert redirect_to("sign in") { sign_in_path }
      end
    end
  end
end
