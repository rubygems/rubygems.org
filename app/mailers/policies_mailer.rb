class PoliciesMailer < ApplicationMailer
  self.deliver_later_queue_name = :within_24_hours

  def policy_update_announcement(user)
    @user = user
    email = user.blocked_email.presence || user.email
    mail to: email, reply_to: "legal@rubycentral.org", from: "support@rubygems.org",
      subject: I18n.t("policies_mailer.policy_update_announcement.subject", host: Gemcutter::HOST_DISPLAY)
  end
end
