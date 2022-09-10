require "test_helper"

class OwnershipCallsControllerTest < ActionController::TestCase
  context "When logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    teardown do
      sign_out
    end

    context "on POST to create" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
      end

      context "user is owner of rubygem" do
        context "with correct params" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "Created ownership call for #{@rubygem.name}."
            assert_equal expected_notice, flash[:notice]
          end
          should "create a call" do
            assert_not_nil @rubygem.ownership_calls.find_by(user: @user)
          end
        end

        context "with params missing" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set alert flash" do
            expected_alert = "Note can't be blank"
            assert_equal expected_alert, flash[:alert]
          end
          should "not create a call" do
            assert_nil @rubygem.ownership_calls.find_by(user: @user)
          end
        end

        context "when call is already open" do
          setup do
            create(:ownership_call, rubygem: @rubygem)
            post :create, params: { rubygem_id: @rubygem.name, note: "other small note" }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set alert flash" do
            expected_alert = "Rubygem can have only one open ownership call"
            assert_equal expected_alert, flash[:alert]
          end
          should "not create a call" do
            assert_equal 1, @rubygem.ownership_calls.count
          end
        end
      end

      context "user is not owner of rubygem" do
        setup do
          user = create(:user)
          sign_in_as(user)
          post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
        end
        should respond_with :forbidden
        should "not create a call" do
          assert_nil @rubygem.ownership_calls.find_by(user: @user)
        end
      end
    end

    context "on PATCH to close" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], number: "1.0.0")
      end

      context "user is owner of rubygem" do
        context "ownership call exists" do
          setup do
            create(:ownership_call, rubygem: @rubygem, user: @user, status: "opened")
            patch :close, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("rubygems show") { rubygem_path(@rubygem) }
          should "set success notice flash" do
            expected_notice = "The ownership call for #{@rubygem.name} was closed."
            assert_equal expected_notice, flash[:notice]
          end
          should "update status to close" do
            assert_empty @rubygem.ownership_calls
          end
        end

        context "ownership call does not exist" do
          setup do
            patch :close, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem) }

          should "set try again notice flash" do
            assert_equal "Something went wrong. Please try again.", flash[:alert]
          end
        end
      end

      context "user is not owner of rubygem" do
        setup do
          user = create(:user)
          sign_in_as(user)
          create(:ownership_call, rubygem: @rubygem, user: @user)
          patch :close, params: { rubygem_id: @rubygem.name }
        end
        should respond_with :forbidden
        should "not update status to close" do
          assert_not_empty @rubygem.ownership_calls
        end
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

      context "user has mfa disabled" do
        context "on GET to index" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "not redirect to mfa" do
            assert page.has_content? "Maintainers wanted"
          end
        end

        context "on PATCH to close" do
          setup do
            patch :close, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("the setup mfa page") { new_multifactor_auth_path }
          should "set mfa_redirect_uri" do
            assert_equal close_rubygem_ownership_calls_path, session[:mfa_redirect_uri]
          end
        end

        context "on POST to create" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
          end
          should redirect_to("the setup mfa page") { new_multifactor_auth_path }
          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_calls_path, session[:mfa_redirect_uri]
          end
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
        end

        context "on GET to index" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "not redirect to mfa" do
            assert page.has_content? "Maintainers wanted"
          end
        end

        context "on PATCH to close" do
          setup do
            patch :close, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("edit settings page") { edit_settings_path }
          should "set mfa_redirect_uri" do
            assert_equal close_rubygem_ownership_calls_path, session[:mfa_redirect_uri]
          end
        end

        context "on POST to create" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
          end
          should redirect_to("edit settings page") { edit_settings_path }
          should "set mfa_redirect_uri" do
            assert_equal rubygem_ownership_calls_path, session[:mfa_redirect_uri]
          end
        end
      end

      context "user has MFA set to strong level, expect normal behaviour" do
        setup do
          @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
        end

        context "on GET to index" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "not redirect to mfa" do
            assert page.has_content? "Maintainers wanted"
          end
        end

        context "on PATCH to close" do
          setup do
            create(:ownership_call, rubygem: @rubygem, user: @user, status: "opened")
            patch :close, params: { rubygem_id: @rubygem.name }
          end
          should redirect_to("rubygems show") { rubygem_path(@rubygem) }
        end

        context "on POST to create" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
          end
          should redirect_to("adoptions index") { rubygem_adoptions_path(@rubygem) }
        end
      end
    end
  end

  context "When user not logged in" do
    context "on POST to create" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        post :create, params: { rubygem_id: @rubygem.name, note: "short note" }
      end
      should "redirect to sign in" do
        assert_redirected_to sign_in_path
      end
      should "not create call" do
        assert_empty @rubygem.ownership_calls
      end
    end

    context "on PATCH to close" do
      setup do
        @rubygem = create(:rubygem, number: "1.0.0")
        create(:ownership_call, rubygem: @rubygem)
        patch :close, params: { rubygem_id: @rubygem.name }
      end
      should "redirect to sign in" do
        assert_redirected_to sign_in_path
      end
      should "not close the call" do
        assert_not_empty @rubygem.ownership_calls
      end
    end

    context "on GET to index" do
      setup do
        rubygems = create_list(:rubygem, 3, number: "1.0.0")
        @ownership_calls = []
        rubygems.each do |rubygem|
          @ownership_calls << create(:ownership_call, rubygem: rubygem)
        end
        get :index
      end
      should respond_with :success
      should "not include closed calls" do
        ownership_call = create(:ownership_call, :closed)
        refute page.has_content? ownership_call.rubygem_name
      end
      should "order calls by created date" do
        expected_order = @ownership_calls.reverse.map(&:rubygem_name)
        actual_order = assert_select("a.gems__gem__name").map(&:text)

        expected_order.each_with_index do |expected_gem_name, i|
          assert_match(/#{expected_gem_name}/, actual_order[i])
        end
      end
      should "display entries and total in page info" do
        assert_select "header > p.gems__meter", text: /Displaying all 3 ownership calls/
      end
      should "display correct number of entries" do
        entries = assert_select("a.gems__gem__name")
        assert_equal 3, entries.size
      end
    end
  end
end
