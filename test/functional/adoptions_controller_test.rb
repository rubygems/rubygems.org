require 'test_helper'

class AdoptionsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, handle: "johndoe")
    @rubygem = create(:rubygem)
    sign_in_as(@user)
  end

  context "on GET to index" do
    setup do
      get :index, params: { rubygem_id: @rubygem.name }
    end

    should respond_with :success
  end

  context "on POST to create" do
    context "with status requested" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note", status: "requested" } }
      end

      should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
      should "set flash success" do
        assert_equal flash[:success], "Adoption request sent to owner of #{@rubygem.name}"
      end
      should "set requested adoption status" do
        assert_equal @user.adoptions.find_by(rubygem_id: @rubygem.id).status, "requested"
      end
    end

    context "with status unknown" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note", status: "unknown" } }
      end

      should respond_with :bad_request
      should "not create adoption" do
        assert_empty @user.adoptions
      end
    end

    context "with status seeked" do
      context "when user is owner of gem" do
        setup do
          @rubygem.ownerships.create(user: @user)
          post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note", status: "seeked" } }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
        should "set flash success" do
          assert_equal flash[:success], "#{@rubygem.name} has been put up for adoption"
        end
        should "set seeked adoption status" do
          assert_equal @user.adoptions.find_by(rubygem_id: @rubygem.id).status, "seeked"
        end
      end

      context "when user is not owner of gem" do
        setup do
          post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note", status: "seeked" } }
        end

        should respond_with :bad_request
        should "not create adoption" do
          assert_empty @user.adoptions
        end
      end
    end
  end

  context "on PUT to update" do
    context "with status approved" do
      context "when user is owner of gem" do
        setup do
          @adoption = create(:adoption, rubygem: @rubygem)
          @rubygem.ownerships.create(user: @user)
          put :update, params: { rubygem_id: @rubygem.name, id: @adoption.id, status: "approved" }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
        should "set flash success" do
          assert_equal flash[:success], "#{@adoption.user.name}'s adoption request for #{@rubygem.name} has been approved"
        end
        should "set approved adoption status" do
          @adoption.reload
          assert_equal @adoption.status, "approved"
        end
        should "add user as owner" do
          assert @rubygem.owned_by?(@adoption.user)
        end
      end

      context "when user is not owner of gem" do
        setup do
          @adoption = create(:adoption, rubygem: @rubygem)
          put :update, params: { rubygem_id: @rubygem.name, id: @adoption.id, status: "approved" }
        end

        should respond_with :bad_request
        should "not set approved adoption status" do
          @adoption.reload
          assert_not_equal @adoption.status, "approved"
        end
      end
    end

    context "with status canceled" do
      context "when user created adoption" do
        setup do
          @adoption = create(:adoption, user: @user)
          put :update, params: { rubygem_id: @rubygem.name, id: @adoption.id, status: "canceled" }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
        should "set flash success" do
          assert_equal flash[:success], "#{@user.name}'s adoption request for #{@rubygem.name} has been canceled"
        end
        should "set canceled adoption status" do
          @adoption.reload
          assert_equal @adoption.status, "canceled"
        end
      end

      context "when user is owner of gem" do
        setup do
          @adoption = create(:adoption, rubygem: @rubygem)
          @rubygem.ownerships.create(user: @user)
          put :update, params: { rubygem_id: @rubygem.name, id: @adoption.id, status: "canceled" }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
        should "set flash success" do
          assert_equal flash[:success], "#{@adoption.user.name}'s adoption request for #{@rubygem.name} has been canceled"
        end
        should "set canceled adoption status" do
          @adoption.reload
          assert_equal @adoption.status, "canceled"
        end
      end

      context "when user is neither owner nor adoption requester" do
        setup do
          @adoption = create(:adoption, rubygem: @rubygem)
          put :update, params: { rubygem_id: @rubygem.name, id: @adoption.id, status: "canceled" }
        end

        should respond_with :bad_request
        should "not set canceled adoption status" do
          @adoption.reload
          assert_not_equal @adoption.status, "canceled"
        end
      end
    end
  end
end
