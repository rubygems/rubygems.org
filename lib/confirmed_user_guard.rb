class ConfirmedUserGuard < Clearance::SignInGuard
  def call
    if user_unconfirmed?
      failure I18n.t('mailer.confirm_your_email')
    else
      next_guard
    end
  end

  def user_unconfirmed?
    signed_in? && !current_user.email_confirmed
  end
end
