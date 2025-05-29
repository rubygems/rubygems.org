require "test_helper"

class PoliciesMailerTest < ActionMailer::TestCase
  setup do
    @user = create(:user)
  end

  test "send policy update announcement" do
    email = PoliciesMailer.policy_update_announcement(@user)
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_equal I18n.t("policies_mailer.policy_update_announcement.subject", host: Gemcutter::HOST_DISPLAY), email.subject
  end

  test "send policy announcement to user with blocked email" do
    @user.email = "blocked@rubygems.org"
    @user.blocked_email = "original-email@example.com"
    @user.save!

    PoliciesMailer.policy_update_announcement(@user).deliver_now

    refute_empty ActionMailer::Base.deliveries
    email = ActionMailer::Base.deliveries.last

    assert_equal [@user.blocked_email], email.to
    assert_equal I18n.t("policies_mailer.policy_update_announcement.subject", host: Gemcutter::HOST_DISPLAY), email.subject
  end
end
