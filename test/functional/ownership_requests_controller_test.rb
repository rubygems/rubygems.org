require "test_helper"

class OwnershipRequestsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on POST to create" do
      context "for popular gem" do
        setup do
          @rubygem = create(:rubygem, downloads: 2_000_000)
          create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
        end
        context "when user is owner" do
          setup do
            create(:ownership, user: @user, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
          end

          should respond_with :forbidden

          should "not create ownership request" do
            assert_nil @rubygem.ownership_requests.find_by(user: @user)
          end
        end

        context "when user is not an owner" do
          context "ownership call exists" do
            setup do
              create(:ownership_call, rubygem: @rubygem)
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }

            should "create ownership request" do
              assert_not_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end

          context "ownership call doesn't exist" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should respond_with :forbidden

            should "not create ownership request" do
              assert_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
        end
      end

      context "for less popular gem" do
        setup do
          @rubygem = create(:rubygem, downloads: 2_000)
          create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
        end

        context "when user is owner" do
          setup do
            create(:ownership, user: @user, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
          should set_flash[:alert].to("User is already an owner")

          should "not create ownership call" do
            assert_nil @rubygem.ownership_requests.find_by(user: @user)
          end
        end

        context "when user is not an owner" do
          context "with correct params" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
            end
            should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
            should set_flash[:notice].to("Your ownership request was submitted.")

            should "create ownership request" do
              assert_not_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
          context "with missing params" do
            setup do
              post :create, params: { rubygem_id: @rubygem.name }
            end
            should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
            should set_flash[:alert].to("Note can't be blank")

            should "not create ownership call" do
              assert_nil @rubygem.ownership_requests.find_by(user: @user)
            end
          end
          context "when request from user exists" do
            setup do
              create(:ownership_request, rubygem: @rubygem, user: @user, note: "other note")
              post :create, params: { rubygem_id: @rubygem.name, note: "new note" }
            end
            should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
            should set_flash[:alert].to("User has already requested ownership")
          end
        end
      end
    end

    context "on PATCH to update" do
      setup do
        @rubygem = create(:rubygem, downloads: 2_000_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
      end
      context "when user is owner and verified" do
        setup do
          create(:ownership, user: @user, rubygem: @rubygem)
          session[:verification] = 10.minutes.from_now
          session[:verified_user] = @user.id
        end

        teardown do
          session[:verification] = nil
          session[:verified_user] = nil
        end

        context "on close" do
          setup do
            @requester = create(:user)
            ownership_request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              patch :update, params: { rubygem_id: @rubygem.name, id: ownership_request.id, status: "close" }
            end
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
          should "set success notice flash" do
            expected_notice = "Ownership request was closed."

            assert_equal expected_notice, flash[:notice]
          end
          should "send email notifications" do
            assert_emails 1
            assert_equal "Your ownership request was closed.", last_email.subject
            assert_equal [@requester.email], last_email.to
          end
        end

        context "on approve" do
          setup do
            @requester = create(:user)
            ownership_request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
              patch :update, params: { rubygem_id: @rubygem.name, id: ownership_request.id, status: "approve" }
            end
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
          should "set success notice flash" do
            expected_notice = "Ownership request was approved. #{@user.display_id} is added as an owner."

            assert_equal expected_notice, flash[:notice]
          end
          should "add ownership record" do
            ownership = Ownership.find_by(rubygem: @rubygem, user: @requester)

            refute_nil ownership
            assert_predicate ownership, :confirmed?
          end
          should "send email notification" do
            assert_emails 3
            request_approved_subjects = ActionMailer::Base.deliveries.map(&:subject)

            assert_contains request_approved_subjects, "Your ownership request was approved."
            assert_contains request_approved_subjects, "User #{@requester.handle} was added as an owner to #{@rubygem.name} gem"

            owner_removed_email_to = ActionMailer::Base.deliveries.map(&:to).flatten.uniq

            assert_same_elements @rubygem.owners.pluck(:email), owner_removed_email_to
          end
        end

        context "on incorrect status" do
          setup do
            @requester = create(:user)
            request = create(:ownership_request, rubygem: @rubygem, user: @requester)
            patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "random" }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }

          should "set try again flash" do
            assert_equal "Something went wrong. Please try again.", flash[:alert]
          end
        end
      end

      context "when user is owner and not verified" do
        setup do
          create(:ownership, user: @user, rubygem: @rubygem)
          @requester = create(:user)
          ownership_request = create(:ownership_request, rubygem: @rubygem, user: @requester)
          patch :update, params: { rubygem_id: @rubygem.name, id: ownership_request.id, status: "close" }
        end
        should redirect_to("verify page") { verify_session_path }
      end

      context "when user is not an owner" do
        setup do
          request = create(:ownership_request, rubygem: @rubygem)
          session[:verification] = 10.minutes.from_now
          session[:verified_user] = @user.id
          patch :update, params: { rubygem_id: @rubygem.name, id: request.id, status: "close" }
        end

        teardown do
          session[:verification] = nil
          session[:verified_user] = nil
        end

        should respond_with :forbidden
      end
    end

    context "on PATCH to close_all" do
      setup do
        @rubygem = create(:rubygem, downloads: 2_000_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
      end
      context "when user is owner and verified" do
        setup do
          create(:ownership, rubygem: @rubygem, user: @user)
          create_list(:ownership_request, 3, rubygem: @rubygem)
          session[:verification] = 10.minutes.from_now
          session[:verified_user] = @user.id
        end

        teardown do
          session[:verification] = nil
          session[:verified_user] = nil
        end

        context "with successful update" do
          setup do
            patch :close_all, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
          should "set success notice flash" do
            expected_notice = "All open ownership requests for #{@rubygem.name} were closed."

            assert_equal expected_notice, flash[:notice]
          end
          should "close all open requests" do
            assert_empty @rubygem.ownership_requests
          end
        end

        context "with unsuccessful update" do
          setup do
            OwnershipRequest.any_instance.stubs(:update!).raises(ActiveRecord::RecordNotSaved)
            patch :close_all, params: { rubygem_id: @rubygem.name }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
          should "set success notice flash" do
            expected_notice = "Something went wrong. Please try again."

            assert_equal expected_notice, flash[:alert]
          end
        end
      end

      context "when user is owner and not verified" do
        setup do
          create(:ownership, rubygem: @rubygem, user: @user)
          patch :close_all, params: { rubygem_id: @rubygem.name }
        end
        should redirect_to("verify page") { verify_session_path }
      end

      context "user is not owner" do
        setup do
          create_list(:ownership_request, 3, rubygem: @rubygem)
          patch :close_all, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :forbidden

        should "not close all open requests" do
          assert_equal 3, @rubygem.ownership_requests.count
        end
      end
    end

    context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
      setup do
        @mfa_rubygem = create(:rubygem)
        create(:ownership, rubygem: @mfa_rubygem, user: @user)
        GemDownload.increment(
          Rubygem::MFA_REQUIRED_THRESHOLD + 1,
          rubygem_id: @mfa_rubygem.id
        )
        @rubygem = create(:rubygem)
        create(:ownership_call, rubygem: @rubygem)
        @ownership_request = create(:ownership_request)
      end

      context "user has mfa disabled" do
        context "POST to create" do
          setup { post :create, params: { rubygem_id: @rubygem.name, note: "small note" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_requests_path, session[:mfa_redirect_uri]
          end
        end

        context "PATCH to close_all" do
          setup { patch :close_all, params: { rubygem_id: @rubygem.name } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal close_all_rubygem_ownership_requests_path, session[:mfa_redirect_uri]
          end
        end

        context "PATCH to update" do
          setup { patch :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_request_path, session[:mfa_redirect_uri]
          end
        end

        context "PUT to update" do
          setup { put :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_request_path, session[:mfa_redirect_uri]
          end
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
        end

        context "POST to create" do
          setup { post :create, params: { rubygem_id: @rubygem.name, note: "small note" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_requests_path, session[:mfa_redirect_uri]
          end
        end

        context "PATCH to close_all" do
          setup do
            patch :close_all, params: { rubygem_id: @rubygem.name }
          end

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal close_all_rubygem_ownership_requests_path, session[:mfa_redirect_uri]
          end
        end

        context "PATCH to update" do
          setup { patch :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_request_path, session[:mfa_redirect_uri]
          end
        end

        context "PUT to update" do
          setup { put :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" } }

          should redirect_to("the edit settings page") { edit_settings_path }

          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_request_path, session[:mfa_redirect_uri]
          end
        end
      end

      context "user has MFA set to strong level, expect normal behaviour" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          session[:verification] = 10.minutes.from_now
          session[:verified_user] = @user.id
        end

        teardown do
          session[:verification] = nil
          session[:verified_user] = nil
        end

        context "POST to create" do
          setup { post :create, params: { rubygem_id: @rubygem.name, note: "small note" } }

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
        end

        context "PATCH to close_all" do
          setup do
            create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
            create(:ownership, rubygem: @rubygem, user: @user)
            create_list(:ownership_request, 3, rubygem: @rubygem)

            patch :close_all, params: { rubygem_id: @rubygem.name }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
        end

        context "PATCH to update" do
          setup do
            @requester = create(:user)
            create(:ownership_request, rubygem: @rubygem, user: @requester)
            patch :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
        end

        context "PUT to update" do
          setup do
            @requester = create(:user)
            create(:ownership_request, rubygem: @rubygem, user: @requester)
            put :update, params: { rubygem_id: @rubygem.name, id: @ownership_request.id, status: "closed" }
          end

          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem.slug) }
        end
      end
    end
  end

  context "when not logged in" do
    setup do
      @rubygem = create(:rubygem, downloads: 2_000)
      create(:version, rubygem: @rubygem, created_at: 2.years.ago, number: "1.0.0")
    end

    context "on POST to create" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, note: "small note" }
      end
      should redirect_to("sign in") { sign_in_path }
    end

    context "on PATCH to update" do
      setup do
        ownership_request = create(:ownership_request)
        patch :update, params: { rubygem_id: ownership_request.rubygem_name, id: ownership_request.id, status: "closed" }
      end
      should redirect_to("sign in") { sign_in_path }
    end

    context "on PATCH to close_all" do
      setup do
        create_list(:ownership_request, 3, rubygem: @rubygem)
        patch :close_all, params: { rubygem_id: @rubygem.name }
      end
      should redirect_to("sign in") { sign_in_path }
    end
  end
end
