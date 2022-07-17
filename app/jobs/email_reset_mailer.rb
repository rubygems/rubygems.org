EmailResetMailer = Struct.new(:user_id) do
  def perform
    user = User.find(user_id)

    if user.confirmation_token.blank?
      return Rails.logger.info("[jobs:email_reset_mailer] confirmation token not found. skipping sending mail for #{user.handle}")
    end

    if user.unconfirmed_email.blank?
      return Rails.logger.info("[jobs:email_reset_mailer] unconfirmed email not found. skipping sending mail for #{user.handle}")
    end

    Mailer.email_reset_update(user).deliver
    Mailer.email_reset(user).deliver
  end
end
