require "test_helper"

class OwnersControllerTest < ActionController::TestCase

  context "When logged in" do
    setup do
      @user = create(:user)
      @rubygem = create(:rubygem)
      create(:ownership, user: @user, rubygem: @rubygem)
      sign_in_as(@user)
    end

    context "on GET to index" do
      context "when user owns the gem" do
        setup do
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should respond_with :success
        should "render all gem owners in owners table" do
          @rubygem.ownerships.each do |o|
            assert page.has_content?(o.user.name)
          end
        end
      end

      context "when user does not own the gem" do
        setup do
          @other_user = create(:user)
          sign_in_as(@other_user)
          get :index, params: { rubygem_id: @rubygem.name }
        end

        should redirect_to("the sign in page") { sign_in_path }
      end
    end

    context "on POST to create ownership" do
      setup do
        @new_owner = create(:user)
        post :create, params: { owner: @new_owner.handle, rubygem_id: @rubygem.name }
      end

      should redirect_to("ownerships index") { rubygem_owners_path(@rubygem) }
      should "add unconfirmed ownership record" do
        assert @rubygem.owners_including_unconfirmed.include?(@new_owner)
        assert_nil @rubygem.ownerships.find_by(user: @new_owner).confirmed_at
      end
      should "set success notice flash" do
        expected_notice = "Owner added successfully. A confirmation mail has been sent to #{@new_owner.handle}'s email"
        assert_equal expected_notice, flash[:notice]
      end
    end

    context "on DELETE to owners" do
      setup do
        @owner = create(:user)
        @ownership = create(:ownership, rubygem: @rubygem, user: @owner)
      end

      context "remove user as gem owner" do
        setup do
          delete :destroy, params: { rubygem_id: @rubygem.name, id: @ownership.id }
        end
        should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
        should "remove the ownership record" do
          refute @rubygem.owners_including_unconfirmed.include?(@owner)
        end
      end

      context "not remove last confirmed owner" do
        setup do
          @ownership.destroy
          @last_ownership = @rubygem.ownerships.last
          delete :destroy, params: { rubygem_id: @rubygem.name, id: @last_ownership.id }
        end
        should redirect_to("ownership index") { rubygem_owners_path(@rubygem) }
        should "remove the ownership record" do
          assert @rubygem.owners_including_unconfirmed.include?(@last_ownership.user)
        end
        should "should flash error" do
          assert_equal "Owner cannot be removed!", flash[:alert]
        end
      end
    end

    context "on GET to resend confirmation" do
      setup do
        @new_owner = create(:user)
        @ownership = create(:ownership, :unconfirmed, rubygem: @rubygem, user: @new_owner)
        sign_in_as(@new_owner)
        get :resend_confirmation, params: { rubygem_id: @rubygem.name }
      end

      should redirect_to("rubygem show") { rubygem_path(@rubygem) }
      should "set success notice flash" do
        success_flash = "A confirmation mail has been re-sent to #{@new_owner.handle}'s email"
        assert_equal success_flash, flash[:notice]
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
        @ownership = create(:ownership, :unconfirmed, user: @user, rubygem: @rubygem)
      end

      context "when token has not expired" do
        should "confirm ownership" do
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          @ownership.reload
          assert @ownership.confirmed?
          assert redirect_to("rubygem show") { rubygem_path(@rubygem) }
          assert_equal flash[:notice], "You are added as an owner to #{@rubygem.name} gem!"
        end
      end

      context "when token has expired" do
        setup do
          @ownership.token_expires_at = Time.current - 2.hours
          @ownership.save
        end
        should "warn about invalid token" do
          get :confirm, params: { rubygem_id: @rubygem.name, token: @ownership.token }
          assert respond_with :success
          assert_equal flash[:alert], "The confirmation token has expired. Please try resending the token"
          assert @ownership.unconfirmed?
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
  end
end
