# frozen_string_literal: true

require "test_helper"

class HistoricalOwnershipsControllerTest < ActionController::TestCase
  context "when not logged in" do
    context "on GET to index" do
      setup { get :index }

      should redirect_to("the sign in page") { sign_in_path }
    end

    context "on PATCH to update" do
      setup { patch :update, params: { id: 1, private: true } }

      should redirect_to("the sign in page") { sign_in_path }
    end
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on GET to index" do
      setup do
        @rubygem = create(:rubygem)
        @historical_ownership = create(:historical_ownership, user: @user, rubygem: @rubygem, removed_at: Time.current)

        get :index
      end

      should respond_with :success

      should "list the user's own historical ownerships" do
        assert_includes assigns(:historical_ownerships), @historical_ownership
      end
    end

    context "on PATCH to update for the user's own historical ownership" do
      setup do
        @historical_ownership = create(:historical_ownership, user: @user, private_at: nil)
      end

      should "make the ownership private" do
        patch :update, params: { id: @historical_ownership.id, private: true }

        assert_predicate @historical_ownership.reload, :private?
        assert_redirected_to profile_historical_ownerships_path
      end

      should "make the ownership public again" do
        @historical_ownership.update!(private_at: Time.current)

        patch :update, params: { id: @historical_ownership.id, private: false }

        refute_predicate @historical_ownership.reload, :private?
      end
    end

    context "on PATCH to update for another user's historical ownership" do
      setup do
        other_user = create(:user)
        @historical_ownership = create(:historical_ownership, user: other_user, private_at: nil)

        patch :update, params: { id: @historical_ownership.id, private: true }
      end

      should respond_with :not_found

      should "not change the other user's ownership privacy" do
        refute_predicate @historical_ownership.reload, :private?
      end
    end
  end
end
