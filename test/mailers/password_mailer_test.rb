# frozen_string_literal: true

require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  test "change password with handle" do
    user = create(:user)
    user.forgot_password!
    email = PasswordMailer.change_password(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal I18n.t("clearance.models.clearance_mailer.change_password"), email.subject
    assert_match user.handle, email.text_part.body.to_s
    assert_match user.handle, email.html_part.body.to_s
  end

  test "change password without handle should show email" do
    user = create(:user, handle: nil)
    user.forgot_password!
    email = PasswordMailer.change_password(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal I18n.t("clearance.models.clearance_mailer.change_password"), email.subject
    assert_match user.email, email.text_part.body.to_s
    assert_match user.email, email.html_part.body.to_s
  end

  test "compromised password reset with handle" do
    user = create(:user)
    user.forgot_password!
    email = PasswordMailer.compromised_password_reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal I18n.t("password_mailer.compromised_password_reset.subject", host: Gemcutter::HOST_DISPLAY), email.subject
    assert_match user.handle, email.text_part.body.to_s
    assert_match user.handle, email.html_part.body.to_s
    assert_match "data breach", email.html_part.body.to_s
    assert_match "data breach", email.text_part.body.to_s
    assert_match "reason=compromised", email.html_part.body.to_s
    assert_match "reason=compromised", email.text_part.body.to_s
    assert_no_match "Someone", email.html_part.body.to_s
    assert_no_match "Someone", email.text_part.body.to_s
  end

  test "compromised password reset without handle should show email" do
    user = create(:user, handle: nil)
    user.forgot_password!
    email = PasswordMailer.compromised_password_reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal I18n.t("password_mailer.compromised_password_reset.subject", host: Gemcutter::HOST_DISPLAY), email.subject
    assert_match user.email, email.text_part.body.to_s
    assert_match user.email, email.html_part.body.to_s
    assert_match "data breach", email.html_part.body.to_s
    assert_match "data breach", email.text_part.body.to_s
  end
end
