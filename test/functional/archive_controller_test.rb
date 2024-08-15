require "test_helper"

class ArchiveControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    @rubygem = create(:rubygem)
    @ownership = create(:ownership, rubygem: @rubygem, user: @user)
  end

  context "on POST to create" do
    context "when not signed in" do
      setup do
        post :create, params: { rubygem_id: "a_gem" }
      end

      should "redirect to sign in page" do
        assert_redirected_to sign_in_path
      end
    end

    context "when the user is signed in and authorized" do
      setup do
        verified_sign_in_as(@user)
        post :create, params: { rubygem_id: @rubygem.name }
      end

      should "archive the gem" do
        assert_predicate @rubygem.reload, :archived?
      end

      should "redirect the user to the gem page" do
        assert_redirected_to rubygem_path(@rubygem)
      end

      should "set a succesfull notice message" do
        assert_equal I18n.t("archive.create.success"), flash[:notice]
      end
    end
  end

  context "on DELETE to destroy" do
    context "when the user is not signed in" do
      setup do
        delete :destroy, params: { rubygem_id: @rubygem.name }
      end

      should "redirect to sign in page" do
        assert_redirected_to sign_in_path
      end
    end

    context "when the user is signed in and authorized" do
      setup do
        verified_sign_in_as(@user)
        delete :destroy, params: { rubygem_id: @rubygem.name }
      end

      should "unarchive the gem" do
        assert_not @rubygem.reload.archived?
      end

      should "redirect the user to the gem page" do
        assert_redirected_to rubygem_path(@rubygem)
      end

      should "set a successfull notice message" do
        assert_equal I18n.t("archive.destroy.success"), flash[:notice]
      end
    end
  end
end
