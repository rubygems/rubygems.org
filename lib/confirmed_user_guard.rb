class ConfirmedUserGuard < Clearance::SignInGuard
  def call
    if user_confirmed?
      next_guard
    else
      failure I18n.t('mailer.confirm_your_email')
    end
  end

  def user_confirmed?
    signed_in? && current_user.email_confirmed
  end
end
