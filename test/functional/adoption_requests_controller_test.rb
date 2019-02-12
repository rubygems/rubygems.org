require 'test_helper'

class AdoptionRequestsControllerTest < ActionController::TestCase
  context "when logged in" do
    setup do
      @user = create(:user, handle: "johndoe")
      @rubygem = create(:rubygem)
      sign_in_as(@user)
    end

    context "on POST to create" do
      context "when save passes" do
        setup do
          post :create, params: { rubygem_id: @rubygem.name, adoption_request: { note: "example note" } }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoption_path(@rubygem) }
        should "set flash success" do
          assert_equal "Adoption request sent to owner(s) of #{@rubygem.name}", flash[:success]
        end
        should "set adoption request with status opened" do
          assert_equal "opened", @user.adoption_requests.find_by(rubygem_id: @rubygem.id).status
        end
      end

      context "when save fails" do
        setup do
          AdoptionRequest.any_instance.stubs(:save).returns(false)
          post :create, params: { rubygem_id: @rubygem.name, adoption_request: { note: "example note" } }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoption_path(@rubygem) }
        should "not create adoption request" do
          assert_empty @rubygem.adoption_requests
        end
      end
    end

    context "on PUT to update" do
      context "with status approved" do
        context "when user is owner of gem" do
          setup do
            @adoption_request = create(:adoption_request, rubygem: @rubygem)
            @rubygem.ownerships.create(user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "approved" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoption_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@adoption_request.user.name}'s adoption request for #{@rubygem.name} has been approved", flash[:success]
          end
          should "set approved adoption request status" do
            @adoption_request.reload
            assert_equal "approved", @adoption_request.status
          end
          should "add user as owner" do
            assert @rubygem.owned_by?(@adoption_request.user)
          end
        end

        context "when user is not owner of gem" do
          setup do
            @adoption_request = create(:adoption_request, rubygem: @rubygem)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "approved" } }
          end

          should respond_with :bad_request
          should "not set approved adoption request status" do
            @adoption_request.reload
            assert_not_equal "approved", @adoption_request.status
          end
        end
      end

      context "with status closed" do
        context "when user created adoption request" do
          setup do
            @adoption_request = create(:adoption_request, user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "closed" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoption_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@user.name}'s adoption request for #{@rubygem.name} has been closed", flash[:success]
          end
          should "set closed adoption_request status" do
            @adoption_request.reload
            assert_equal "closed", @adoption_request.status
          end
        end

        context "when user is owner of gem" do
          setup do
            @adoption_request = create(:adoption_request, rubygem: @rubygem)
            @rubygem.ownerships.create(user: @user)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "closed" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoption_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@adoption_request.user.name}'s adoption request for #{@rubygem.name} has been closed", flash[:success]
          end
          should "set closed adoption request status" do
            @adoption_request.reload
            assert_equal "closed", @adoption_request.status
          end
        end

        context "when user is neither owner nor adoption request requester" do
          setup do
            @adoption_request = create(:adoption_request, rubygem: @rubygem)
            put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "closed" } }
          end

          should respond_with :bad_request
          should "not set closed adoption request status" do
            @adoption_request.reload
            assert_not_equal "closed", @adoption_request.status
          end
        end
      end
    end
  end

  context "when not logged in" do
    setup do
      @rubygem = create(:rubygem)
    end

    context "on POST to create" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption_request: { note: "example note" } }
      end

      should redirect_to("home") { root_path }
      should "not create adoption request" do
        assert_empty @rubygem.adoption_requests
      end
    end

    context "on PUT to update" do
      setup do
        @adoption_request = create(:adoption_request, rubygem: @rubygem)
        put :update, params: { rubygem_id: @rubygem.name, id: @adoption_request.id, adoption_request: { status: "approved" } }
      end

      should redirect_to("home") { root_path }
      should "not approve adoption request" do
        assert_equal "opened", @adoption_request.status
      end
    end
  end
end
