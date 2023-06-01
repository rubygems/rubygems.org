require "application_system_test_case"

class WebauthnCredentialsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
  end

  def sign_in
    visit sign_in_path
    fill_in "Email or Username", with: @user.reload.email
    fill_in "Password", with: @user.password
    click_button "Sign in"
  end

  should "have security device form" do
    sign_in
    visit edit_settings_path

    assert_text "Register a new security device"
    assert_text "SECURITY DEVICE"
    assert_text "You don't have any security devices"
    assert page.has_field?("Nickname")
    assert page.has_button?("Register device")
  end

  should "show the security device" do
    sign_in
    @primary = create(:webauthn_credential, :primary, user: @user)
    @backup = create(:webauthn_credential, :backup, user: @user)
    visit edit_settings_path

    assert_text "SECURITY DEVICE"
    assert_no_text "You don't have any security devices"
    assert_text "Register a new security device"
    assert_text @primary.nickname
    assert_text @backup.nickname
    assert page.has_button?("Delete")
    assert page.has_field?("Nickname")
    assert page.has_button?("Register device")
  end

  should "be able to delete security devices" do
    sign_in
    @webauthn_credential = create(:webauthn_credential, user: @user)
    visit edit_settings_path

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      assert_text "SECURITY DEVICE"
      assert_no_text "You don't have any security devices"
      assert_text @webauthn_credential.nickname

      click_on "Delete"
      page.accept_alert

      assert_text "You don't have any security devices"
      assert_no_text @webauthn_credential.nickname
    end

    webauthn_credential_removed_email = ActionMailer::Base.deliveries.find do |email|
      email.to.include?(@user.email)
    end

    assert_equal "Security device removed on RubyGems.org", webauthn_credential_removed_email.subject
  end

  should "not delete device if confirmation alert is dismissed" do
    sign_in
    @webauthn_credential = create(:webauthn_credential, user: @user)
    visit edit_settings_path

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      assert_text "SECURITY DEVICE"
      assert_no_text "You don't have any security devices"
      assert_text @webauthn_credential.nickname

      click_on "Delete"
      page.dismiss_confirm

      assert_no_text "You don't have any security devices"
      assert_text @webauthn_credential.nickname
    end

    webauthn_credential_removed_email = ActionMailer::Base.deliveries.find do |email|
      email.to.include?(@user.email)
    end

    assert_nil webauthn_credential_removed_email
  end

  should "be able to create security devices" do
    sign_in
    visit edit_settings_path

    assert_text "You don't have any security devices"

    options = ::Selenium::WebDriver::VirtualAuthenticatorOptions.new
    authenticator = page.driver.browser.add_virtual_authenticator(options)
    WebAuthn::PublicKeyCredentialWithAttestation.any_instance.stubs(:verify).returns true

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      @credential_nickname = "new cred"
      fill_in "Nickname", with: @credential_nickname
      click_on "Register device"

      assert page.has_content? "Recovery codes"
    end

    assert_equal recovery_multifactor_auth_path, current_path
    click_on "[ copy ]"
    check "ack"
    click_on "Continue"

    assert_equal edit_settings_path, current_path

    webauthn_credential_creation_email = ActionMailer::Base.deliveries.find do |email|
      email.to.include?(@user.email)
    end

    assert_equal "New security device added on RubyGems.org", webauthn_credential_creation_email.subject

    # Cleanup test data
    authenticator.remove!
  end
end
