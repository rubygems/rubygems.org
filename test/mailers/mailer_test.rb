# frozen_string_literal: true

require "test_helper"

class MailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @user = create(:user)
  end

  context "#email_reset_update" do
    should "include host in subject" do
      email = Mailer.email_reset_update(@user)

      assert_emails(1) { email.deliver_now }

      assert_includes email.subject, Gemcutter::HOST_DISPLAY
    end

    should "explain that the change needs the confirmation form to be submitted" do
      @user.update!(unconfirmed_email: "new@mailinator.com")
      email = Mailer.email_reset_update(@user).deliver_now
      body = email.body.to_s

      assert_includes body, I18n.t("mailer.email_reset_update.pending_change", host: Gemcutter::HOST_DISPLAY, email: @user.email)
      assert_includes body, "“Confirm email address”"
      refute_includes body, "Once you click on confirmation link"
    end
  end

  context "#email_confirmation" do
    should "render the confirmation link as a button" do
      @user.update_column(:email_confirmed, false)
      email = Mailer.email_confirmation(@user, @user.email).deliver_now
      token = confirmation_token_from_email(email)

      assert_cta_button update_email_confirmations_url(token:, host: Gemcutter::HOST), "VERIFY"
      refute_equal token, @user.reload.email_confirmation_token_digest
      assert @user.valid_email_confirmation_token?(token)
      assert_in_delta 24.hours.from_now, @user.email_confirmation_token_expires_at, 2.seconds
    end
  end

  context "#email_reset" do
    should "render the confirmation link as a button" do
      @user.update!(unconfirmed_email: "new@mailinator.com")
      email = Mailer.email_reset(@user, @user.unconfirmed_email).deliver_now
      token = confirmation_token_from_email(email)

      assert_cta_button update_email_confirmations_url(token:, host: Gemcutter::HOST), "VERIFY"
      assert @user.valid_email_confirmation_token?(token)
      assert_in_delta 3.hours.from_now, @user.email_confirmation_token_expires_at, 2.seconds
    end

    should "skip jobs enqueued without a target email" do
      @user.update!(unconfirmed_email: "new@mailinator.com")

      email = Mailer.email_reset(@user).deliver_now

      assert_nil email
      assert_nil @user.reload.email_confirmation_token_digest
    end
  end

  private

  def confirmation_token_from_email(email)
    uri = URI(email.body.encoded[%r{https?://[^\s<]+/email_confirmations/confirm\?token=[^\s<]+}])
    Rack::Utils.parse_query(uri.query).fetch("token")
  end
end
