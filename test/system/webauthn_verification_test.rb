# frozen_string_literal: true

require "application_system_test_case"

class WebAuthnVerificationTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    create_webauthn_credential
    @verification = create(:webauthn_verification, user: @user, otp: nil, otp_expires_at: nil)
    @port = 1
  end

  test "when verifying webauthn credential" do
    assert_poll_status("pending")
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })

    assert_text "Authenticate with Security Device"
    assert_text "Authenticating as #{@user.handle}".upcase

    click_on "Authenticate"

    assert_text "Success!"
    assert_current_path(successful_verification_webauthn_verification_path)

    assert_link_is_expired
    assert_poll_status("success")
    assert_successful_verification_not_found
  end

  test "when webauthn verification is expired during verification" do
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })

    travel 3.minutes do
      assert_text "Authenticate with Security Device"
      assert_text "Authenticating as #{@user.handle}".upcase

      click_on "Authenticate"

      assert redirect_to(failed_verification_webauthn_verification_path)
      assert_text "The token in the link you used has either expired or been used already."
      assert_text "Please close this browser and try again."
      assert_failed_verification_not_found
    end
  end

  def teardown
    @authenticator&.remove!
    Capybara.use_default_driver
  end

  private

  def assert_link_is_expired
    visit webauthn_verification_path(webauthn_token: @verification.path_token, params: { port: @port })

    assert_text "The token in the link you used has either expired or been used already."
  end

  def assert_poll_status(status)
    @api_key ||= create(:api_key, key: "12345", scopes: %i[push_rubygem], owner: @user)

    Capybara.current_driver = :rack_test
    page.driver.header "AUTHORIZATION", "12345"

    visit status_api_v1_webauthn_verification_path(webauthn_token: @verification.path_token, format: :json)

    assert_equal status, JSON.parse(page.text)["status"]
    fullscreen_headless_chrome_driver
  end

  def assert_successful_verification_not_found
    visit successful_verification_webauthn_verification_path

    assert_text "Page not found."
  end

  def assert_failed_verification_not_found
    visit failed_verification_webauthn_verification_path

    assert_text "Page not found."
  end
end
