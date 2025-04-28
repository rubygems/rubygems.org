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

  test "send policy update review closed" do
    email = PoliciesMailer.policy_update_review_closed(@user)
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_equal I18n.t("policies_mailer.policy_update_review_closed.subject", host: Gemcutter::HOST_DISPLAY), email.subject
  end
end
