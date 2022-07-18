EmailResetMailer = Struct.new(:user_id) do
  def perform
    user = User.find(user_id)
    return if user.confirmation_token.blank?

    Mailer.email_reset_update(user).deliver if user.email
    Mailer.email_reset(user).deliver if user.unconfirmed_email
  end
end
