require "application_system_test_case"

class FeatureFlaggingTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  test "feature flag UI is protected" do
    visit "/admin/features"

    assert_text "To reach the admin panel, please log in via GitHub"

    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    visit "/admin/features"

    assert_text "Features"
  end

  test "enabling feature flags" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    allowed_user = create(:user)

    visit "/admin/features"

    assert_text "Features"

    click_link "Add Feature"

    fill_in "value", with: "my_feature"
    click_button "Add Feature"

    assert_text "my_feature"
    click_button "Add an actor"

    fill_in "value", with: "user:#{allowed_user.handle}"
    click_button "Add Actor"

    assert_text "user:#{allowed_user.handle}"
    assert_text "Remove"

    click_button "Remove"
    assert_no_text "user:#{allowed_user.handle}"
  end
end
