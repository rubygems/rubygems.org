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
  end

  context "#email_confirmation" do
    should "render the confirmation link as a button" do
      @user.generate_confirmation_token
      Mailer.email_confirmation(@user).deliver_now

      assert_cta_button update_email_confirmations_url(token: @user.confirmation_token, host: Gemcutter::HOST), "VERIFY"
    end
  end

  context "#email_reset" do
    should "render the confirmation link as a button" do
      @user.update!(unconfirmed_email: "new@mailinator.com")
      Mailer.email_reset(@user).deliver_now

      assert_cta_button update_email_confirmations_url(token: @user.confirmation_token, host: Gemcutter::HOST), "VERIFY"
    end
  end
end
