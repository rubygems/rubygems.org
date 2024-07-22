require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
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
end
