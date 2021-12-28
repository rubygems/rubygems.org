require "test_helper"

class ApiKeysTest < SystemTest
  setup do
    @user = create(:user)

    visit sign_in_path
    fill_in "Email or Username", with: @user.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  test "creating new api key" do
    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    refute page.has_content? "Enable MFA"
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert @user.api_keys.last.can_index_rubygems?
    refute @user.api_keys.last.mfa_enabled?
  end

  test "creating new api key with MFA UI enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)

    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    check "mfa"
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert @user.api_keys.last.mfa_enabled?
  end

  test "creating new api key with MFA UI and API enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)

    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert @user.api_keys.last.mfa_enabled?
  end

  test "update api key" do
    api_key = create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    check "api_key[add_owner]"
    refute page.has_content? "Enable MFA"
    click_button "Update"

    assert api_key.reload.can_add_owner?
  end

  test "update api key with MFA UI enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)

    api_key = create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    check "api_key[add_owner]"
    check "mfa"
    click_button "Update"

    assert api_key.reload.can_add_owner?
    assert @user.api_keys.last.mfa_enabled?
  end

  test "update api key with MFA UI and API enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)

    api_key = create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    check "api_key[add_owner]"
    refute page.has_content? "Enable MFA"
    click_button "Update"

    assert api_key.reload.can_add_owner?
    assert @user.api_keys.last.mfa_enabled?
  end

  test "deleting api key" do
    create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Delete"

    assert page.has_content? "New API key"
  end

  test "deleting all api key" do
    create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Reset"

    assert page.has_content? "New API key"
  end

  def visit_profile_api_keys_path
    visit profile_api_keys_path
    return unless page.has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end
end
