require "application_system_test_case"

class ApiKeysTest < ApplicationSystemTestCase
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

    assert_nil URI.parse(current_url).query

    fill_in "Name", with: "my-api-key"
    check "Index rubygems"

    refute has_content? "Enable MFA"
    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :can_index_rubygems?
    refute_predicate @user.api_keys.last, :mfa_enabled?
    assert_nil @user.api_keys.last.rubygem

    assert_event Events::UserEvent::API_KEY_CREATED, {
      name: "my-api-key",
      scopes: ["index_rubygems"],
      mfa: false,
      api_key_gid: @user.api_keys.last.to_global_id.to_s
    }, @user.events.where(tag: Events::UserEvent::API_KEY_CREATED).sole
  end

  test "creating new api key from index" do
    create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "New API key"

    assert_empty URI.parse(current_url).query

    fill_in "Name", with: "my-api-key"
    check "Index rubygems"

    refute has_content? "Enable MFA"
    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :can_index_rubygems?
    refute_predicate @user.api_keys.last, :mfa_enabled?
    assert_nil @user.api_keys.last.rubygem
  end

  test "creating new api key scoped to a gem" do
    visit_profile_api_keys_path

    fill_in "Name", with: "my-api-key"
    check "Push rubygem"

    assert has_select? "api_key_rubygem_id", selected: "All Gems"
    select @ownership.rubygem.name
    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_equal @ownership.rubygem.name, find('.owners__cell[data-title="Gem"]').text
    assert_equal @ownership.rubygem, @user.api_keys.last.rubygem
  end

  (ApiKey::API_SCOPES - ApiKey::APPLICABLE_GEM_API_SCOPES).each do |scope|
    test "creating new api key cannot set gem scope with #{scope} scope selected" do
      visit_profile_api_keys_path
      check I18n.t("api_keys.index.#{scope}")

      assert has_select? "api_key_rubygem_id", selected: "All Gems", disabled: true
    end
  end

  ApiKey::APPLICABLE_GEM_API_SCOPES.each do |scope|
    test "creating new api key scoped to a gem with #{scope} scope" do
      visit_profile_api_keys_path
      fill_in "Name", with: "my-api-key"
      check I18n.t("api_keys.index.#{scope}")

      assert has_select? "api_key_rubygem_id", selected: "All Gems"
      select @ownership.rubygem.name
      click_button "Create API Key"

      assert has_content? "Note that we won't be able to show the key to you again. New API key:"
      assert_equal @ownership.rubygem, @user.api_keys.last.rubygem
    end
  end

  test "selecting the exclusive scope deselects the other scopes and vice versa" do
    visit_profile_api_keys_path

    fill_in "Name", with: "my-api-key"
    check "Index rubygems"
    check "Push rubygem"

    assert has_select? "api_key_rubygem_id", selected: "All Gems"

    select @ownership.rubygem.name

    assert has_select? "api_key_rubygem_id", selected: @ownership.rubygem.name

    check "Show dashboard"

    assert has_select? "api_key_rubygem_id", selected: "All Gems", disabled: true
    assert has_unchecked_field? "Index rubygems"
    assert has_unchecked_field? "Push rubygem"

    check "Index rubygems"

    assert has_unchecked_field? "Show dashboard"

    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :can_index_rubygems?
  end

  test "creating new api key scoped to gem that the user does not own" do
    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "my-api-key"
    check "api_key[push_rubygem]"

    assert has_select? "api_key_rubygem_id", selected: "All Gems"
    select @ownership.rubygem.name

    @ownership.destroy!
    click_button "Create API Key"

    assert has_css? ".flash"
    assert has_content? "Rubygem must be a gem that you are an owner of"
    assert_empty @user.api_keys
  end

  test "creating new api key with MFA UI enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

    visit_profile_api_keys_path

    fill_in "api_key[name]", with: "my-api-key"
    check "api_key[index_rubygems]"
    check "mfa"
    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "creating new api key with expiration" do
    visit_profile_api_keys_path

    expiration = 1.day.from_now.beginning_of_minute

    fill_in "api_key[name]", with: "my-api-key"
    check "api_key[index_rubygems]"
    fill_in "api_key[expires_at]", with: expiration
    click_button "Create API Key"

    assert_text "Note that we won't be able to show the key to you again. New API key:"
    assert_equal expiration.strftime("%Y-%m-%d %H:%M %Z"), find('.owners__cell[data-title="Expiration"]').text
    assert_equal expiration, @user.api_keys.last.expires_at
  end

  test "creating new api key with MFA UI and API enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

    visit_profile_api_keys_path

    fill_in "Name", with: "my-api-key"
    check "Index rubygems"
    click_button "Create API Key"

    assert has_content? "Note that we won't be able to show the key to you again. New API key:"
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "update api key scope" do
    api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert_empty URI.parse(current_url).query
    assert has_content? "Edit API key"
    check "Add owner"

    refute has_content? "Enable MFA"
    click_button "Update API Key"

    assert_predicate api_key.reload, :can_add_owner?
  end

  test "update api key gem scope" do
    api_key = create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    assert has_select? "Gem Scope", selected: @ownership.rubygem.name

    select "All Gems"
    click_button "Update API Key"

    assert_equal "All Gems", find('.owners__cell[data-title="Gem"]').text
    assert_nil api_key.reload.rubygem
  end

  test "update gem scoped api key with applicable scopes removed" do
    api_key = create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    check "Index rubygems"
    uncheck "Push rubygem"

    assert has_select? "Gem Scope", selected: "All Gems", disabled: true
    click_button "Update API Key"

    assert_nil api_key.reload.rubygem
  end

  test "update gem scoped api key to another applicable scope" do
    api_key = create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    uncheck "Push rubygem"

    assert has_select? "Gem Scope", selected: "All Gems", disabled: true

    check "Yank rubygem"
    select @ownership.rubygem.name
    click_button "Update API Key"

    assert_equal api_key.reload.rubygem, @ownership.rubygem
  end

  test "update api key gem scope to a gem the user does not own" do
    api_key = create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)
    @another_ownership = create(:ownership, user: @user, rubygem: create(:rubygem, name: "another_gem"))

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    assert has_select? "Gem Scope", selected: @ownership.rubygem.name
    select "another_gem"

    @another_ownership.destroy!
    click_button "Update API Key"

    assert has_css? ".flash"
    assert has_content? "Rubygem must be a gem that you are an owner of"
    assert_equal @ownership.rubygem, api_key.reload.rubygem
  end

  test "update api key with MFA UI enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

    api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    check "Add owner"
    check "mfa"
    click_button "Update API Key"

    assert_predicate api_key.reload, :can_add_owner?
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "update api key with MFA UI and API enabled" do
    @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

    api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    check "Add owner"

    refute has_content? "Enable MFA"
    click_button "Update API Key"

    assert_predicate api_key.reload, :can_add_owner?
    assert_predicate @user.api_keys.last, :mfa_enabled?
  end

  test "disable expires_at field" do
    _api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Edit"

    assert has_content? "Edit API key"
    assert has_field? "Expiration", disabled: true
  end

  test "deleting api key" do
    api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Delete"

    accept_alert

    assert has_content? "New API key"
    assert_text "Successfully deleted API key: #{api_key.name}"

    assert_event Events::UserEvent::API_KEY_DELETED, { name: api_key.name, api_key_gid: api_key.to_global_id.to_s },
      @user.events.where(tag: Events::UserEvent::API_KEY_DELETED).sole
  end

  test "deleting all api key" do
    api_key = create(:api_key, owner: @user)

    visit_profile_api_keys_path
    click_button "Reset"

    accept_alert

    assert has_content? "New API key"
    assert_no_text api_key.name
  end

  test "gem ownership removed displays api key as invalid" do
    api_key = create(:api_key, scopes: %i[push_rubygem], owner: @user, ownership: @ownership)
    visit_profile_api_keys_path

    refute has_css? ".owners__row__invalid"

    @ownership.destroy!

    visit_profile_api_keys_path

    assert has_css? ".owners__row__invalid"
    assert_predicate api_key.reload, :soft_deleted?

    refute has_button? "Edit"
    assert_equal "#{@ownership.rubygem.name} [?]", find('.owners__cell[data-title="Gem"]').text
    visit_edit_profile_api_key_path(api_key)

    assert has_content? "An invalid API key cannot be edited. Please delete it and create a new one."
    assert_equal profile_api_keys_path, current_path
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
    return unless has_css? "#verify_password_password"

    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Confirm"
  end
end
