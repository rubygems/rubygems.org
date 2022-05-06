require "test_helper"

class ApiKeysControllerTest < ActionController::TestCase
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
      setup { post :create, params: { id: 1 } }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on DELETE to destroy" do
      setup { delete :reset }

      should redirect_to("the sign in page") { sign_in_path }
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
      session[:verification] = 10.minutes.from_now
    end

    teardown do
      session[:verification] = nil
    end

    context "on GET to index" do
      context "no api key exists" do
        setup do
          get :index
        end

        should redirect_to("the new api key page") { new_profile_api_key_path }
      end

      context "api key exists" do
        setup do
          @api_key = create(:api_key, user: @user)
          get :index
        end

        should respond_with :success

        should "render api key of user" do
          assert page.has_content? @api_key.name
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
          post :create, params: { api_key: { name: "test", add_owner: true } }
          Delayed::Worker.new.work_off
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

          assert_equal "Rubygem that is selected cannot be scoped to this key", flash[:error]
          assert_empty @user.reload.api_keys
        end

        should "displays error with gem scope without applicable scope enabled" do
          post :create, params: { api_key: { name: "gem scope", index_rubygems: true, rubygem_id: @ownership.rubygem.id } }

          assert_equal "Rubygem scope can only be set for push/yank rubygem, and add/remove owner scopes", flash[:error]
          assert_empty @user.reload.api_keys
        end
      end
    end

    context "on GET to edit" do
      setup do
        @api_key = create(:api_key, user: @user)
        get :edit, params: { id: @api_key.id }
      end

      should respond_with :success

      should "render edit api key form" do
        assert page.has_content? "Edit API key"
        assert_select "form > input.form__input", value: "ci-key"
      end

      should "redirect to index with soft deleted key" do
        @api_key.soft_delete!
        get :edit, params: { id: @api_key.id }

        assert_redirected_to profile_api_keys_path
        assert_equal "An invalid API key cannot be edited. Please delete it and create a new one.", flash[:error]
      end
    end

    context "on PATCH to update" do
      setup { @api_key = create(:api_key, user: @user) }

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
          patch :update, params: { api_key: { name: "", add_owner: true }, id: @api_key.id }
        end

        should "show error to user" do
          assert page.has_content? "Name can't be blank"
        end

        should "not update scope of test key" do
          refute_predicate @api_key, :can_add_owner?
        end
      end

      context "gem scope" do
        setup do
          @ownership = create(:ownership, user: @user, rubygem: create(:rubygem))
          @api_key.update(rubygem_id: @ownership.rubygem.id, push_rubygem: true)
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

            assert_equal "Rubygem that is selected cannot be scoped to this key", flash[:error]
          end
        end

        should "displays error with gem scope without applicable scope enabled" do
          assert_no_changes @api_key do
            patch :update, params: { api_key: { push_rubygem: false }, id: @api_key.id }

            assert_equal "Rubygem scope can only be set for push/yank rubygem, and add/remove owner scopes", flash[:error]
          end
        end
      end
    end

    context "on DELETE to destroy" do
      context "user is owner of key" do
        setup { @api_key = create(:api_key, user: @user) }

        context "with successful destroy" do
          setup { delete :destroy, params: { id: @api_key.id } }

          should redirect_to("the index api key page") { profile_api_keys_path }
          should "delete api key of user" do
            assert_empty @user.api_keys
          end
        end

        context "with unsuccessful destroy" do
          setup do
            ApiKey.any_instance.stubs(:destroy).returns(false)
            delete :destroy, params: { id: @api_key.id }
          end

          should redirect_to("the index api key page") { profile_api_keys_path }
          should "not delete api key of user" do
            refute_empty @user.api_keys
          end
        end
      end

      context "user is not owner of key" do
        setup do
          @api_key = create(:api_key)
          delete :destroy, params: { id: @api_key.id }
        end

        should respond_with :not_found
        should "not delete the api key" do
          assert ApiKey.find(@api_key.id)
        end
      end
    end

    context "on DELETE to reset" do
      setup do
        create(:api_key, key: "1234", user: @user)
        create(:api_key, key: "2345", user: @user)

        delete :reset
      end

      should redirect_to("the index api key page") { profile_api_keys_path }
      should "delete all api key of user" do
        assert_empty @user.api_keys
      end
    end
  end
end
