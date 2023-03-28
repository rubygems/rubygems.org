module EmailResettable
  extend ActiveSupport::Concern

  included do
    def email_reset(user)
      return if user.confirmation_token.blank?

      Mailer.email_reset_update(user).deliver_later if user.email
      Mailer.email_reset(user).deliver_later if user.unconfirmed_email
    end
  end
end
