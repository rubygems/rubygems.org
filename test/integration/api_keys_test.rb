require "test_helper"

class ApiKeysTest < SystemTest
  setup do
    @user = create(:user)
    @ownership = create(:ownership, user: @user, rubygem: create(:rubygem))

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
    assert_predicate @user.api_keys.last, :can_index_rubygems?
    refute_predicate @user.api_keys.last, :mfa_enabled?
    assert_nil @user.api_keys.last.rubygem
  end

  test "creating new api key scoped to a gem" do
    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    assert page.has_select? "api_key_rubygem_id", selected: nil
    page.select @ownership.rubygem.name
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_equal @ownership.rubygem, @user.api_keys.last.rubygem
  end

  test "creating new api key scoped to gem that the user does not own" do
    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    assert page.has_select? "api_key_rubygem_id", selected: nil
    page.select @ownership.rubygem.name

    @ownership.destroy!
    click_button "Create"

    assert page.has_css? ".flash"
    assert page.has_content? "Selected gem cannot be scoped to this key"
    assert_empty @user.api_keys
  end

  test "creating new api key with MFA UI enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)

    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    check "mfa"
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "creating new api key with MFA UI and API enabled" do
    @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)

    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "test"
    check "api_key[index_rubygems]"
    click_button "Create"

    assert page.has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "update api key scope" do
    api_key = create(:api_key, user: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    check "api_key[add_owner]"
    refute page.has_content? "Enable MFA"
    click_button "Update"

    assert_predicate api_key.reload, :can_add_owner?
  end

  test "update api key gem scope" do
    api_key = create(:api_key, user: @user, ownership: @ownership)

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    assert page.has_select? "api_key_rubygem_id", selected: @ownership.rubygem.name
    page.select "All Gems"
    click_button "Update"

    assert_nil api_key.reload.rubygem
  end

  test "update api key gem scope to a gem the user does not own" do
    api_key = create(:api_key, user: @user, ownership: @ownership)
    @another_ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "another_gem"))

    visit_profile_api_keys_path
    click_button "Edit"

    assert page.has_content? "Edit API key"
    assert page.has_select? "api_key_rubygem_id", selected: @ownership.rubygem.name
    page.select "another_gem"

    @another_ownership.destroy!
    click_button "Update"

    assert page.has_css? ".flash"
    assert page.has_content? "Selected gem cannot be scoped to this key"
    assert_equal @ownership.rubygem, api_key.reload.rubygem
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

    assert_predicate api_key.reload, :can_add_owner?
    assert_predicate @user.api_keys.last, :mfa_enabled?
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

    assert_predicate api_key.reload, :can_add_owner?
    assert_predicate @user.api_keys.last, :mfa_enabled?
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

  test "gem ownership removed displays api key as invalid" do
    api_key = create(:api_key, user: @user, ownership: @ownership)
    visit_profile_api_keys_path
    refute page.has_css? ".owners__row__invalid"

    @ownership.destroy!

    visit_profile_api_keys_path
    assert page.has_css? ".owners__row__invalid"
    assert api_key.reload.soft_deleted?

    refute page.has_button? "Edit"
    visit_edit_profile_api_key_path(api_key)
    assert page.has_content? "An invalid API key cannot be edited. Please delete it and create a new one."
    assert_equal profile_api_keys_path, page.current_path
  end

  def visit_profile_api_keys_path
    visit profile_api_keys_path
    verify_password
  end

  def visit_edit_profile_api_key_path(api_key)
    visit edit_profile_api_key_path(api_key)
    verify_password
  end

  def verify_password
    return unless page.has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end
end
