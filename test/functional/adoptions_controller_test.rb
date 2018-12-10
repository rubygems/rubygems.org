require 'test_helper'

class AdoptionsControllerTest < ActionController::TestCase
  context "when logged in" do
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
      context "when user is owner" do
        setup { @rubygem.ownerships.create(user: @user) }

        context "save passes" do
          setup do
            @rubygem.ownerships.create(user: @user)
            post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal "#{@rubygem.name} has been put up for adoption", flash[:success]
          end
          should "set save adoption" do
            assert_equal "example note", @user.adoptions.find_by(rubygem_id: @rubygem.id).note
          end
        end

        context "save fails" do
          setup do
            Adoption.any_instance.stubs(:save).returns(false)
            post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note" } }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "not create adoption request" do
            assert_empty @rubygem.adoptions
          end
        end
      end
    end

    context "when user is not owner of gem" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note" } }
      end

      should respond_with :bad_request
      should "not create adoption" do
        assert_empty @user.adoptions
      end
    end

    context "on DELETE to destroy" do
      setup do
        @adoption = create(:adoption, rubygem: @rubygem)
      end

      context "when user is owner of gem" do
        setup { @rubygem.ownerships.create(user: @user) }

        context "destroy passes" do
          setup do
            delete :destroy, params: { rubygem_id: @rubygem.name, id: @adoption.id }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "set flash success" do
            assert_equal "Adoption for #{@rubygem.name} has been deleted", flash[:success]
          end
          should "delete adoption" do
            assert_empty @user.adoptions
          end
        end

        context "destroy fails" do
          setup do
            Adoption.any_instance.stubs(:destroy).returns(false)
            delete :destroy, params: { rubygem_id: @rubygem.name, id: @adoption.id }
          end

          should redirect_to("rubygems adoptions index") { rubygem_adoptions_path(@rubygem) }
          should "not create adoption request" do
            assert_not_empty @rubygem.adoptions
          end
        end
      end

      context "when user is not owner of gem" do
        setup do
          delete :destroy, params: { rubygem_id: @rubygem.name, id: @adoption.id }
        end

        should respond_with :bad_request
        should "not delete adoption" do
          assert_not_empty @rubygem.adoptions
        end
      end
    end
  end

  context "when not logged in" do
    setup do
      @rubygem = create(:rubygem)
    end

    context "on GET to index" do
      setup do
        get :index, params: { rubygem_id: @rubygem.name }
      end

      should respond_with :success
    end

    context "on POST to create" do
      setup do
        post :create, params: { rubygem_id: @rubygem.name, adoption: { note: "example note" } }
      end

      should redirect_to("home") { root_path }
      should "not create adoption" do
        assert_empty @rubygem.adoptions
      end
    end

    context "on DELETE to destroy" do
      setup do
        adoption = create(:adoption, rubygem: @rubygem)
        delete :destroy, params: { rubygem_id: @rubygem.name, id: adoption.id }
      end

      should redirect_to("home") { root_path }
      should "not delete adoption" do
        assert_not_empty @rubygem.adoptions
      end
    end
  end
end
