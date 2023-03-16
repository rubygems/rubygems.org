EmailConfirmationMailer = Struct.new(:user_id) do
  include SemanticLogger::Loggable

  def perform
    user = User.find(user_id)

    if user.confirmation_token
      Mailer.email_confirmation(user).deliver
    else
      logger.info("confirmation token not found. skipping sending mail for #{user.handle}")
    end
  end
end
