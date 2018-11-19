require 'test_helper'

class AdoptionsControllerTest < ActionController::TestCase
  context "signed in user" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      sign_in_as(@user)
    end

    context "on GET to new" do
      setup do
        get :new, params: { rubygem_id: @rubygem.name }
      end

      should respond_with :success
    end

    context "on POST to create" do
      context "with status requested" do
        setup do
          post :create, params: { rubygem_id: @rubygem.name, adoption: {note: "example note", status: "requested" } }
        end

        should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
        should "set flash success" do
          assert_equal flash[:success], "Adoption request sent to owner of #{@rubygem.name}"
        end
      end

      context "with status unknown" do
        setup do
          post :create, params: { rubygem_id: @rubygem.name, adoption: {note: "example note", status: "unknown" } }
        end

        should respond_with :bad_request
      end

      context "with status seeked" do
        context "when user is owner of gem" do
          setup do
            @rubygem.ownerships.create(user: @user)
            post :create, params: { rubygem_id: @rubygem.name, adoption: {note: "example note", status: "seeked" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal flash[:success], "#{@rubygem.name} has been put up for adoption"
          end
        end

        context "when user is not owner of gem" do
          setup do
            post :create, params: { rubygem_id: @rubygem.name, adoption: {note: "example note", status: "seeked" } }
          end

          should respond_with :bad_request
        end
      end
    end
  end
end
