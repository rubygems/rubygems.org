# frozen_string_literal: true

require "test_helper"

class ApiKeysControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "when not logged in" do
    context "on GET to index" do
      setup { get :index }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on GET to new" do
      setup { get :new }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on POST to create" do
      setup { post :create, params: { api_key: { name: "test", add_owner: true } } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on GET to edit" do
      setup { get :edit, params: { id: 1 } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on PATCH to update" do
      setup { patch :update, params: { api_key: { name: "test", add_owner: true }, id: 1 } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on DELETE to destroy" do
      setup { delete :destroy, params: { id: 1 } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on DELETE to reset" do
      setup { delete :reset }

      should redirect_to("the sign in page") { sign_in_path }
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      session[:verification] = 10.minutes.from_now
      session[:verified_user] = @user.id
    end

    teardown do
      session[:verification] = nil
      session[:verified_user] = nil
    end

    context "on GET to index" do
      context "no api key exists" do
        setup do
          get :index
        end

        should redirect_to("the new api key page") { new_profile_api_key_path }
      end

      context "only expired keys exist" do
        setup do
          @expired_key = create(:api_key, owner: @user, name: "expired-key")
          @expired_key.update_column(:expires_at, 1.week.ago)
          get :index
        end

        should respond_with :success

        should "not list the expired key in the active view" do
          refute page.has_content? @expired_key.name
        end

        should "render a link to view previous keys" do
          assert page.has_link? "View previous API keys", href: profile_api_keys_path(expired: "true")
        end
      end

      context "no api key exists and the expired view is requested" do
        setup do
          get :index, params: { expired: "true" }
        end

        should respond_with :success
      end

      context "api key exists" do
        setup do
          @api_key = create(:api_key, owner: @user)
          get :index
        end

        should respond_with :success

        should "render api key of user" do
          assert page.has_content? @api_key.name
        end

        should "render on the subject layout with settings active" do
          assert_select "h1", text: "API keys"
          assert_select "nav a[href=?].bg-orange-100", edit_settings_path
        end
      end

      context "user has no expired keys" do
        setup do
          create(:api_key, owner: @user)
          get :index
        end

        should "not render a link to view previous keys" do
          refute page.has_link? "View previous API keys"
        end
      end

      context "user has expired keys" do
        setup do
          @active_key = create(:api_key, owner: @user, name: "active-key")
          @expired_key = create(:api_key, owner: @user, name: "expired-key")
          @expired_key.update_column(:expires_at, 1.week.ago)
        end

        context "without the expired param" do
          setup { get :index }

          should respond_with :success

          should "list only active keys" do
            assert page.has_content? @active_key.name
            refute page.has_content? @expired_key.name
          end

          should "render a link to view previous keys" do
            assert page.has_link? "View previous API keys", href: profile_api_keys_path(expired: "true")
          end

          should "render the reset button" do
            assert page.has_button? "Reset"
          end
        end

        context "with the expired param" do
          setup { get :index, params: { expired: "true" } }

          should respond_with :success

          should "list only expired keys" do
            assert page.has_content? @expired_key.name
            refute page.has_content? @active_key.name
          end

          should "not render edit or delete buttons" do
            refute page.has_button? "Edit"
            refute page.has_button? "Delete"
          end

          should "not render the reset button" do
            refute page.has_button? "Reset"
          end

          should "render the new key button" do
            assert page.has_button? "New API key"
          end

          should "render a link back to active keys" do
            assert page.has_link? "Back to active API keys", href: profile_api_keys_path
          end
        end

        should "order previous keys by expiration descending" do
          ancient_key = create(:api_key, owner: @user, name: "ancient-key")
          ancient_key.update_column(:expires_at, 2.weeks.ago)
          get :index, params: { expired: "true" }

          assert_operator response.body.index(@expired_key.name), :<, response.body.index(ancient_key.name)
        end

        should "not list expired OIDC keys" do
          oidc_key = create(:api_key, owner: @user, name: "oidc-key", scopes: %i[push_rubygem])
          create(:oidc_id_token, api_key: oidc_key)
          oidc_key.update_column(:expires_at, 1.week.ago)
          get :index, params: { expired: "true" }

          refute page.has_content? oidc_key.name
        end

        should "render the gem name for an expired key whose gem ownership was removed" do
          ownership = create(:ownership, user: @user, rubygem: create(:rubygem))
          orphaned_key = create(:api_key, owner: @user, name: "orphaned-key", scopes: %i[push_rubygem], ownership: ownership)
          ownership.destroy!
          orphaned_key.update_column(:expires_at, 3.days.ago)
          get :index, params: { expired: "true" }

          tooltip = "Ownership of the #{ownership.rubygem.name} gem has been removed after being scoped to this key."

          assert page.has_css? "span[title='#{tooltip}']", text: "#{ownership.rubygem.name} [?]"
          refute page.has_css? "tr.opacity-60"
        end
      end
    end

    context "on GET to new" do
      setup { get :new }

      should respond_with :success

      should "render new api key form" do
        assert page.has_content? "New API key"
      end
    end

    context "on POST to create" do
      context "with successful save" do
        setup do
          perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
            post :create, params: { api_key: { name: "test", add_owner: true } }
          end
        end

        should redirect_to("the key index page") { profile_api_keys_path }
        should "create new key for user" do
          api_key = @user.api_keys.last

          assert_equal "test", api_key.name
          assert @controller.session[:api_key]
          assert_predicate api_key, :can_add_owner?
        end
        should "deliver api key created email" do
          refute_empty ActionMailer::Base.deliveries
          email = ActionMailer::Base.deliveries.last

          assert_equal [@user.email], email.to
          assert_equal ["no-reply@mailer.rubygems.org"], email.from
          assert_equal "New API key created for rubygems.org", email.subject
        end
      end

      context "with unsuccessful save" do
        setup { post :create, params: { api_key: { add_owner: true } } }

        should "show error to user" do
          assert page.has_content? "Name can't be blank"
        end

        should "not create new key for user" do
          assert_empty @user.reload.api_keys
        end
      end

      context "with a gem scope" do
        setup do
          @ownership = create(:ownership, user: @user, rubygem: create(:rubygem))
        end

        should "have a gem scope with valid id" do
          post :create, params: { api_key: { name: "gem scope", add_owner: true, rubygem_id: @ownership.rubygem.id } }

          created_key = @user.reload.api_keys.find_by(name: "gem scope")

          assert_equal @ownership.rubygem, created_key.rubygem
        end

        should "display error with invalid id" do
          post :create, params: { api_key: { name: "gem scope", add_owner: true, rubygem_id: -1 } }

          assert_equal "Rubygem must be a gem that you are an owner of", flash[:error]
          assert_empty @user.reload.api_keys
        end

        should "displays error with gem scope without applicable scope enabled" do
          post :create, params: { api_key: { name: "gem scope", index_rubygems: true, rubygem_id: @ownership.rubygem.id } }

          assert_equal "Rubygem scope can only be set for push/yank rubygem, and add/remove owner scopes", flash[:error]
          assert_empty @user.reload.api_keys
        end
      end

      context "with an expiration" do
        should "create a key" do
          expires_at = 1.month.from_now
          post :create, params: { api_key: { name: "expiration", add_owner: true, expires_at: } }

          created_key = @user.reload.api_keys.sole

          assert_equal expires_at.change(usec: 0), created_key.expires_at
        end

        should "display error with invalid expiration" do
          expires_at = 1.month.ago
          post :create, params: { api_key: { name: "expiration", add_owner: true, expires_at: } }

          assert_includes flash[:error], "Expires at must be in the future"
          assert_empty @user.reload.api_keys
        end
      end
    end

    context "on GET to edit" do
      setup do
        @api_key = create(:api_key, owner: @user)
        get :edit, params: { id: @api_key.id }
      end

      should respond_with :success

      should "render edit api key form" do
        assert page.has_content? "Edit API key"
        assert_select "form input#api_key_name[value=?]", "ci-key"
      end

      should "redirect to index with soft deleted key" do
        @api_key.soft_delete!
        get :edit, params: { id: @api_key.id }

        assert_redirected_to profile_api_keys_path
        assert_equal "An invalid API key cannot be edited. Please delete it and create a new one.", flash[:error]
      end

      should "redirect to index with expired key" do
        @api_key.update_column(:expires_at, 1.hour.ago)
        get :edit, params: { id: @api_key.id }

        assert_redirected_to profile_api_keys_path
        assert_equal "An expired API key cannot be edited. Please create a new one.", flash[:error]
      end

      should "prefer the soft deleted error for a key both soft deleted and expired" do
        @api_key.soft_delete!
        @api_key.update_column(:expires_at, 1.hour.ago)
        get :edit, params: { id: @api_key.id }

        assert_redirected_to profile_api_keys_path
        assert_equal "An invalid API key cannot be edited. Please delete it and create a new one.", flash[:error]
      end
    end

    context "on PATCH to update" do
      setup { @api_key = create(:api_key, owner: @user) }

      context "with successful save" do
        setup do
          patch :update, params: { api_key: { name: "test", add_owner: true }, id: @api_key.id }
          @api_key.reload
        end

        should redirect_to("the key index page") { profile_api_keys_path }

        should "update test key scope" do
          assert_predicate @api_key, :can_add_owner?
        end
      end

      context "with unsuccessful save" do
        setup do
          patch :update, params: { api_key: { name: "", add_owner: true, show_dashboard: true }, id: @api_key.id }
        end

        should "show error to user" do
          assert_text "Show dashboard scope must be enabled exclusively"
        end

        should "not update scope of test key" do
          refute_predicate @api_key, :can_add_owner?
        end
      end

      context "gem scope" do
        setup do
          @ownership = create(:ownership, user: @user, rubygem: create(:rubygem))
          @api_key.update(rubygem_id: @ownership.rubygem.id, scopes: %i[push_rubygem])
        end

        should "to all gems" do
          patch :update, params: { api_key: { rubygem_id: nil }, id: @api_key.id }

          assert_nil @api_key.reload.rubygem
        end

        should "to another gem" do
          another_ownership = create(:ownership, user: @user, rubygem: create(:rubygem))
          patch :update, params: { api_key: { rubygem_id: another_ownership.rubygem.id }, id: @api_key.id }

          assert_equal another_ownership.rubygem, @api_key.reload.rubygem
        end

        should "displays error with invalid id" do
          assert_no_changes @api_key do
            patch :update, params: { api_key: { rubygem_id: -1 }, id: @api_key.id }

            assert_equal "Rubygem must be a gem that you are an owner of", flash[:error]
          end
        end

        should "displays error with gem scope without applicable scope enabled" do
          assert_no_changes @api_key do
            patch :update, params: { api_key: { push_rubygem: false }, id: @api_key.id }
          end
          assert_equal "Please enable at least one scope and Rubygem scope can only be set for push/yank rubygem, and add/remove owner scopes",
                       flash[:error]
        end
      end

      context "with an expired key" do
        setup do
          @api_key.update_column(:expires_at, 1.hour.ago)
          patch :update, params: { api_key: { add_owner: true }, id: @api_key.id }
        end

        should "show error to user" do
          assert_text "An expired API key cannot be used. Please create a new one."
        end

        should "not update scope of the key" do
          refute_predicate @api_key.reload, :can_add_owner?
        end
      end

      context "with an expiration" do
        should "not allow chaging expiration" do
          @api_key.update_column(:expires_at, 1.month.from_now)
          expires_at = 1.year.from_now

          assert_no_changes -> { @api_key.reload.expires_at } do
            patch :update, params: { api_key: { expires_at: }, id: @api_key.id }

            assert_response :bad_request
          end
        end

        should "not allow adding expiration" do
          expires_at = 1.year.from_now
          assert_no_changes -> { @api_key.reload.expires_at } do
            patch :update, params: { api_key: { expires_at: }, id: @api_key.id }

            assert_response :bad_request
          end
        end
      end
    end

    context "on DELETE to destroy" do
      context "user is owner of key" do
        setup { @api_key = create(:api_key, owner: @user) }

        context "with successful destroy" do
          setup { delete :destroy, params: { id: @api_key.id } }

          should redirect_to("the index api key page") { profile_api_keys_path }

          should "expire api key of user" do
            assert_empty @user.api_keys.unexpired
            refute_empty @user.api_keys
          end
        end

        context "with unsuccessful destroy" do
          setup do
            ApiKey.any_instance.stubs(:expire!).returns(false)
            delete :destroy, params: { id: @api_key.id }
          end

          should redirect_to("the index api key page") { profile_api_keys_path }

          should "not expire api key of user" do
            refute_empty @user.api_keys.unexpired
          end
        end

        context "with an already-expired key" do
          setup do
            @api_key.update_column(:expires_at, 1.hour.ago)
            @original_expires_at = @api_key.reload.expires_at
            delete :destroy, params: { id: @api_key.id }
          end

          should redirect_to("the index api key page") { profile_api_keys_path }

          should "show an error to the user" do
            assert_equal "The API key has already expired.", flash[:error]
          end

          should "not change the expiration timestamp" do
            assert_equal @original_expires_at, @api_key.reload.expires_at
          end

          should "not record another deletion event" do
            assert_empty @user.events.where(tag: Events::UserEvent::API_KEY_DELETED)
          end
        end
      end

      context "user is not owner of key" do
        setup do
          @api_key = create(:api_key)
          delete :destroy, params: { id: @api_key.id }
        end

        should respond_with :not_found

        should "not expire the api key" do
          refute_predicate ApiKey.find(@api_key.id), :expired?
        end
      end
    end

    context "on DELETE to reset" do
      setup do
        create(:api_key, key: "1234", owner: @user)
        create(:api_key, key: "2345", owner: @user)

        delete :reset
      end

      should redirect_to("the index api key page") { profile_api_keys_path }

      should "expire all api key of user" do
        @user.api_keys.each { assert_predicate it, :expired? }
      end
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
        "DELETE to reset" => { action: :reset, request: { method: "DELETE" }, path: "/profile/api_keys/reset" },
        "GET to index" => { action: :index, request: { method: "GET" }, path: "/profile/api_keys" },
        "GET to new" => { action: :new, request: { method: "GET" }, path: "/profile/api_keys/new" },
        "POST to create" => { action: :create, request: { method: "POST", params: { api_key: { name: "test", add_owner: true } } },
path: "/profile/api_keys" },
        "GET to edit" => { action: :edit, request: { method: "GET", params: { id: 1 } }, path: "/profile/api_keys/1/edit" },
        "PATCH to update" => { action: :update, request: { method: "PATCH", params: { id: 1, api_key: { name: "test", add_owner: true } } },
path: "/profile/api_keys/1" },
        "DELETE to destroy" => { action: :destroy, request: { method: "DELETE", params: { id: 1 } }, path: "/profile/api_keys/1" }
      }

      context "user has mfa disabled" do
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

        context "on DELETE to reset" do
          setup do
            create(:api_key, key: "1234", owner: @user)
            delete :reset
          end

          should redirect_to("the index api key page") { profile_api_keys_path }
        end

        context "on GET to index" do
          setup { get :index }

          should redirect_to("the new api key page") { new_profile_api_key_path }
        end

        context "on GET to new" do
          setup { get :new }

          should respond_with :success

          should "render new api key form" do
            assert page.has_content? "New API key"
          end
        end

        context "on POST to create" do
          setup do
            post :create, params: { api_key: { name: "test", add_owner: true } }
          end

          should redirect_to("the key index page") { profile_api_keys_path }
        end

        context "on GET to edit" do
          setup do
            @api_key = create(:api_key, owner: @user)
            get :edit, params: { id: @api_key.id }
          end

          should respond_with :success

          should "render edit api key form" do
            assert page.has_content? "Edit API key"
          end
        end

        context "on PATCH to update" do
          setup do
            @api_key = create(:api_key, owner: @user)
            patch :update, params: { api_key: { name: "test", add_owner: true }, id: @api_key.id }
            @api_key.reload
          end

          should redirect_to("the index api key page") { profile_api_keys_path }
        end

        context "on DELETE to destroy" do
          setup do
            @api_key = create(:api_key, owner: @user)
            delete :destroy, params: { id: @api_key.id }
          end

          should redirect_to("the index api key page") { profile_api_keys_path }
        end
      end
    end
  end
end
