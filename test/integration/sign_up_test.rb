require "test_helper"
require "helpers/rate_limit_helpers"

class SignUpTest < SystemTest
  include RateLimitHelpers

  setup do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  test "sign up" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
  end

  test "sign up with no handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "errors prohibited"
  end

  test "sign up with bad handle" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "thisusernameiswaytoolongseriouslywaytoolong"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up with someone else's handle" do
    create(:user, handle: "nick")
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "error prohibited"
  end

  test "sign up when sign up is disabled" do
    Clearance.configure { |config| config.allow_sign_up = false }
    Rails.application.reload_routes!

    visit root_path

    refute page.has_content? "Sign up"
    assert_raises(ActionController::RoutingError) do
      visit "/sign_up"
    end
  end

  test "sign up when user param is string" do
    assert_nothing_raised do
      get "/sign_up?user=JJJ12QQQ"
    end
  end

  test "sign up when captcha verification is triggered and verified" do
    @ip = "127.0.0.1"
    @scope = Rack::Attack::SIGN_UP_THROTTLE_PER_IP_KEY
    update_limit_for("#{@scope}:#{@ip}", 2, Rack::Attack::SIGN_UP_LIMIT_PERIOD)
    # captcha is meant to _not_ be machine automatable, so we're stubbing in this case
    HcaptchaVerifier.expects(:call).with(anything, anything).returns(true)

    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "Verify you're human"
    click_button "Verify"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
  end

  test "sign up when captcha verification is triggered and not verified" do
    @ip = "127.0.0.1"
    @scope = Rack::Attack::SIGN_UP_THROTTLE_PER_IP_KEY
    update_limit_for("#{@scope}:#{@ip}", 2, Rack::Attack::SIGN_UP_LIMIT_PERIOD)
    # captcha is meant to _not_ be machine automatable, so we're stubbing in this case
    HcaptchaVerifier.expects(:call).with(anything, anything).returns(false)

    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "Verify you're human"
    click_button "Verify"

    assert page.has_content? "Unable to verify CAPTCHA"
  end

  test "sign up when privacy pass is verified" do
    Rails.configuration.launch_darkly_client.expects(:variation).with("gemcutter.privacy_pass.enabled", anything,
anything).returns(true).at_least_once
    # privacy pass is meant to _not_ be machine automatable, so we're stubbing in this case
    PrivacyPassRedeemer.expects(:call).with(anything, anything).returns(true)

    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
  end

  test "sign up when privacy pass is not verified and captcha is not triggered" do
    Rails.configuration.launch_darkly_client.expects(:variation).with("gemcutter.privacy_pass.enabled", anything,
anything).returns(true).at_least_once
    # privacy pass is meant to _not_ be machine automatable, so we're stubbing in this case
    PrivacyPassRedeemer.expects(:call).with(anything, anything).returns(false)

    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
  end

  test "sign up when privacy pass is not verified and captcha verification is triggered" do
    Rails.configuration.launch_darkly_client.expects(:variation).with("gemcutter.privacy_pass.enabled", anything,
anything).returns(true).at_least_once
    # privacy pass is meant to _not_ be machine automatable, so we're stubbing in this case
    PrivacyPassRedeemer.expects(:call).with(anything, anything).returns(false)

    @ip = "127.0.0.1"
    @scope = Rack::Attack::SIGN_UP_THROTTLE_PER_IP_KEY
    update_limit_for("#{@scope}:#{@ip}", 2, Rack::Attack::SIGN_UP_LIMIT_PERIOD)
    # captcha is meant to _not_ be machine automatable, so we're stubbing in this case
    HcaptchaVerifier.expects(:call).with(anything, anything).returns(true)

    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD
    click_button "Sign up"

    assert page.has_content? "Verify you're human"
    click_button "Verify"

    assert page.has_selector? "#flash_notice", text: "A confirmation mail has been sent to your email address."
  end

  test "email confirmation" do
    visit sign_up_path

    fill_in "Email", with: "email@person.com"
    fill_in "Username", with: "nick"
    fill_in "Password", with: PasswordHelpers::SECURE_TEST_PASSWORD

    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      click_button "Sign up"
    end

    link = last_email_link

    assert_not_nil link
    visit link

    assert page.has_content? "Sign out"
    assert page.has_selector? "#flash_notice", text: "Your email address has been verified"
  end

  teardown do
    Clearance.configure { |config| config.allow_sign_up = true }
    Rails.application.reload_routes!
  end
end
