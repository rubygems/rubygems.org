EmailResetMailer = Struct.new(:user_id) do
  def perform
    user = User.find(user_id)

    if user.confirmation_token
      Mailer.email_reset(user).deliver
    else
      Rails.logger.info("[jobs:email_reset_mailer] confirmation token not found. skipping sending mail for #{user.handle}")
    end
  end
end
