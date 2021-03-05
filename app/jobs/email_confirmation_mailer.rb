EmailConfirmationMailer = Struct.new(:user_id) do
  def perform
    user = User.find(user_id)

    if user.confirmation_token
      Mailer.email_confirmation(user).deliver
    else
      Rails.logger.info("[jobs:email_confirmation_mailer] confirmation token not found. skipping sending mail for #{user.handle}")
    end
  end
end
