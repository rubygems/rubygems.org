require "test_helper"

class OwnersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "When logged in and verified" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: @rubygem)
      sign_in_as(@user)
      session[:verification] = 10.minutes.from_now
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

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          sign_in_as(@other_user)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :forbidden
      end
    end

    context "on POST to create ownership" do
      context "when user owns the gem" do
        context "with invalid handle" do
          setup do
            post :create, params: { handle: "no_user", rubygem_id: @rubygem.name }
          end

          should respond_with :unprocessable_entity

          should "show error message" do
            expected_alert = "User must exist"
            assert_equal expected_alert, flash[:alert]
          end

          should "not send confirmation email" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 0
          end
        end

        context "with valid handle" do
          setup do
            @new_owner = create(:user)
            post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name }
          end

          should redirect_to("ownerships index") { rubygem_owners_path(@rubygem) }
          should "add unconfirmed ownership record" do
            assert_includes @rubygem.owners_including_unconfirmed, @new_owner
            assert_nil @rubygem.ownerships_including_unconfirmed.find_by(user: @new_owner).confirmed_at
          end
          should "set success notice flash" do
            expected_notice = "#{@new_owner.handle} was added as an unconfirmed owner. "\
                              "Ownership access will be enabled after the user clicks on the confirmation mail sent to their email."
            assert_equal expected_notice, flash[:notice]
          end
          should "send confirmation email" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
            assert_emails 1
            assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
            assert_equal [@new_owner.email], last_email.to
          end

          context "when ownership was deleted before running mailer job" do
            setup { @rubygem.owners_including_unconfirmed.last.destroy }

            should "not send confirmation email" do
              ActionMailer::Base.deliveries.clear
              Delayed::Worker.new.work_off
              assert_equal 0, Delayed::Job.where.not(last_error: nil).count
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
              @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
              post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name }
            end

            should redirect_to("ownerships index") { rubygem_owners_path(@rubygem) }

            should "set success notice flash" do
              expected_notice = "#{@new_owner.handle} was added as an unconfirmed owner. "\
                                "Ownership access will be enabled after the user clicks on the confirmation mail sent to their email."
              assert_equal expected_notice, flash[:notice]
            end
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          sign_in_as(@other_user)
          post :create, params: { handle: @other_user.display_id, rubygem_id: @rubygem.name }
        end

        should respond_with :forbidden
        should "not add other user as owner" do
          refute_includes @rubygem.owners_including_unconfirmed, @other_user
        end
      end
    end

    context "on DELETE to owners" do
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
            delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
          end
          should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
          should "remove the ownership record" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
          should "send email notifications about owner removal" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off

            assert_emails 1
            assert_contains last_email.subject, "You were removed as an owner from #{@rubygem.name} gem"
            assert_equal [@second_user.email], last_email.to
          end
        end

        context "with handle of unconfirmed owner" do
          setup do
            @second_user = create(:user)
            @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @second_user)
            delete :destroy, params: { rubygem_id: @rubygem.name, handle: @second_user.display_id }
          end
          should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
          should "remove the ownership record" do
            refute_includes @rubygem.owners_including_unconfirmed, @second_user
          end
          should "send email notifications about owner removal" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off

            assert_emails 1
            assert_contains last_email.subject, "You were removed as an owner from #{@rubygem.name} gem"
            assert_equal [@second_user.email], last_email.to
          end
        end

        context "with handle of last owner" do
          setup do
            @last_owner = @rubygem.owners.last
            delete :destroy, params: { rubygem_id: @rubygem.name, handle: @last_owner.display_id }
          end
          should respond_with :forbidden
          should "not remove the ownership record" do
            assert_includes @rubygem.owners_including_unconfirmed, @last_owner
          end
          should "should flash error" do
            assert_equal "Can't remove the only owner of the gem", flash[:alert]
          end
          should "not send email notifications about owner removal" do
            ActionMailer::Base.deliveries.clear
            Delayed::Worker.new.work_off
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
              @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
              delete :destroy, params: { handle: @second_user.display_id, rubygem_id: @rubygem.name }
            end

            should redirect_to("ownerships index") { rubygem_owners_path(@rubygem) }

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
          sign_in_as(@other_user)

          @last_owner = @rubygem.owners.last
          delete :destroy, params: { rubygem_id: @rubygem.name, handle: @last_owner.display_id }
        end

        should respond_with :forbidden
        should "not remove user as owner" do
          assert_includes @rubygem.owners, @last_owner
        end
      end
    end

    context "on GET to resend confirmation" do
      setup do
        @new_owner = create(:user)
        sign_in_as(@new_owner)
      end

      context "when unconfirmed ownership exists" do
        setup do
          create(:ownership, :unconfirmed, rubygem: @rubygem, user: @new_owner)
          get :resend_confirmation, params: { rubygem_id: @rubygem.name }
        end

        should redirect_to("rubygem show") { rubygem_path(@rubygem) }
        should "set success notice flash" do
          success_flash = "A confirmation mail has been re-sent to your email"
          assert_equal success_flash, flash[:notice]
        end
        should "resend confirmation email" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 1
          assert_equal "Please confirm the ownership of #{@rubygem.name} gem on RubyGems.org", last_email.subject
          assert_equal [@new_owner.email], last_email.to
        end
      end

      context "when ownership doesn't exist" do
        setup do
          get :resend_confirmation, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :not_found
        should "not resend confirmation email" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 0
        end
      end

      context "when confirmed ownership exists" do
        setup do
          create(:ownership, rubygem: @rubygem, user: @new_owner)
          get :resend_confirmation, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :not_found
        should "not resend confirmation email" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
          assert_emails 0
        end
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
        post :create, params: { handle: @new_owner.display_id, rubygem_id: @rubygem.name }
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
      should "remove the ownership record" do
        assert_includes @rubygem.owners_including_unconfirmed, @second_user
      end
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
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          @ownership.reload
        end

        should "confirm ownership" do
          assert @ownership.confirmed?
          assert redirect_to("rubygem show") { rubygem_path(@rubygem) }
          assert_equal "You were added as an owner to #{@rubygem.name} gem", flash[:notice]
        end

        should "not sign in the user" do
          refute @controller.request.env[:clearance].signed_in?
        end

        should "send email notifications about new owner" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off

          owner_added_email_subjects = ActionMailer::Base.deliveries.map(&:subject)
          assert_contains owner_added_email_subjects, "You were added as an owner to #{@rubygem.name} gem"
          assert_contains owner_added_email_subjects, "User #{@user.handle} was added as an owner to #{@rubygem.name} gem"

          owner_added_email_to = ActionMailer::Base.deliveries.map(&:to).flatten
          assert_same_elements @rubygem.owners.map(&:email), owner_added_email_to
        end
      end

      context "when token has expired" do
        setup do
          travel_to Time.current + 3.days
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
        end

        should "warn about invalid token" do
          assert respond_with :success
          assert_equal "The confirmation token has expired. Please try resending the token from the gem page.", flash[:alert]
          assert @ownership.unconfirmed?
        end

        should "not send email notification about owner added" do
          ActionMailer::Base.deliveries.clear
          Delayed::Worker.new.work_off
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
  end
end
