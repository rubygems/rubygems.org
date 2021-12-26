require "test_helper"

class AdoptionsControllerTest < ActionController::TestCase
  context "on GET to index" do
    setup do
      @user = create(:user)
    end
    context "signed user is owner of rubygem" do
      setup do
        @rubygem = create(:rubygem, owners: [@user], downloads: 2_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago)
        sign_in_as @user
        session[:verification] = 10.minutes.from_now
      end

      teardown do
        session[:verification] = nil
      end

      context "ownership call exists" do
        setup do
          @ownership_call = create(:ownership_call, rubygem: @rubygem, user: @user, note: "example call")
        end

        context "ownership request exists" do
          setup do
            @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, note: "example request")
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success

          should "have button for approve and close all ownership requests" do
            assert page.has_content?("example request")
            assert page.has_selector?("input[value='Close']")
            assert page.has_selector?("input[value='Close all']")
          end
        end

        context "ownership request doesn't exist" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success

          should "have button to close ownership call" do
            assert page.has_content?("example call")
            assert page.has_selector?("input[value='Close']")
          end
        end
      end

      context "ownership call doesn't exist" do
        context "ownership request exists" do
          setup do
            @ownership_request = create(:ownership_request, rubygem: @rubygem)
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "have button to create ownership call" do
            assert page.has_selector?("input[value='Create ownership call']")
          end
        end

        context "ownership request doesn't exist" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "not show any ownership request" do
            assert page.has_content?("No ownership requests for #{@rubygem.name}")
          end
        end
      end
    end

    context "signed in user is not owner of rubygem" do
      setup do
        @rubygem = create(:rubygem, downloads: 2_000)
        create(:version, rubygem: @rubygem, created_at: 2.years.ago)
        sign_in_as @user
      end
      context "ownership call exists" do
        setup do
          @ownership_call = create(:ownership_call, rubygem: @rubygem)
        end

        context "ownership request by user exists" do
          setup do
            @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, user: @user, note: "example request")
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "have button to close ownership request" do
            assert page.has_content?("example request")
            assert page.has_selector?("input[value='Close']")
          end
        end

        context "ownership request doesn't exist" do
          setup do
            get :index, params: { rubygem_id: @rubygem.name }
          end
          should respond_with :success
          should "have button to create ownership request" do
            assert page.has_selector?("input[value='Create ownership request']")
          end
        end
      end

      context "ownership call doesn't exist" do
        setup do
          get :index, params: { rubygem_id: @rubygem.name }
        end
        should respond_with :success
        should "not show any ownership request" do
          assert page.has_content?("There are no ownership calls for #{@rubygem.name}")
        end
      end
    end

    context "user is not signed in" do
      context "ownership call and request exits" do
        setup do
          @rubygem = create(:rubygem, downloads: 2_000)
          create(:version, rubygem: @rubygem, created_at: 2.years.ago)
          @ownership_call = create(:ownership_call, rubygem: @rubygem, note: "example call")
          @ownership_request = create(:ownership_request, rubygem: @rubygem, ownership_call: @ownership_call, user: @user, note: "example request")
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :success
        should "not show ownership request or create button" do
          refute page.has_content?("example request")
          refute page.has_selector?("input[value='Create']")
        end
        should "show ownership call" do
          assert page.has_content?("example call")
        end
      end
    end
  end
end
