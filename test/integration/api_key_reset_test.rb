require "test_helper"

class ApiKeyResetTest < SystemTest
  setup do
    @user = create(:user)
  end

  test "reset API key" do
    visit sign_in_path

    fill_in "Email or Username", with: @user.handle
    fill_in "Password", with: @user.password
    click_button "Sign in"

    visit profile_path(@user.handle)
    click_link "Edit Profile"

    old_api_key = @user.api_key
    click_button "Reset my API key"

    assert page.has_content? @user.reload.api_key
    assert_not_equal old_api_key, @user.api_key
  end
end
