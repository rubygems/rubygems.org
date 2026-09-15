# frozen_string_literal: true

require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  test "change password with handle" do
    user = create(:user)
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
    email = PasswordMailer.compromised_password_reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal I18n.t("password_mailer.compromised_password_reset.subject", host: Gemcutter::HOST_DISPLAY), email.subject
    assert_match user.handle, email.text_part.body.to_s
    assert_match user.handle, email.html_part.body.to_s
    assert_match "data breach", email.html_part.body.to_s
    assert_match "data breach", email.text_part.body.to_s
    assert_match "reason=", email.html_part.body.to_s
    assert_match "reason=", email.text_part.body.to_s
    assert_no_match "Someone", email.html_part.body.to_s
    assert_no_match "Someone", email.text_part.body.to_s
  end

  test "compromised password reset without handle should show email" do
    user = create(:user, handle: nil)
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

  test "change password renders the change password link as a button" do
    user = create(:user)
    email = PasswordMailer.change_password(user)
    email.deliver_now
    url = password_reset_url(email)
    token = password_reset_url_params(url).fetch("token")

    assert user.reload.valid_password_reset_token?(token)
    assert_cta_button url, "CHANGE PASSWORD"
  end

  test "compromised password reset renders the change password link as a button" do
    user = create(:user)
    email = PasswordMailer.compromised_password_reset(user)
    email.deliver_now
    url = password_reset_url(email)
    url_params = password_reset_url_params(url)

    assert user.reload.valid_compromised_password_reset_reason?(url_params.fetch("reason"), token: url_params.fetch("token"))
    assert_cta_button url, "CHANGE PASSWORD"
  end

  private

  def password_reset_url(email)
    Nokogiri::HTML(email.html_part.body.decoded).at_css("div.text-btn a")["href"]
  end

  def password_reset_url_params(url)
    Rack::Utils.parse_nested_query(URI.parse(url).query)
  end
end
