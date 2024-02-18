require "test_helper"

class MailerTest < ActionMailer::TestCase
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
end
