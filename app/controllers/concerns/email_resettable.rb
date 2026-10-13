# frozen_string_literal: true

module EmailResettable
  extend ActiveSupport::Concern

  included do
    def email_reset(user)
      return if user.unconfirmed_email.blank?

      Mailer.email_reset_update(user).deliver_later if user.email
      Mailer.email_reset(user, user.unconfirmed_email).deliver_later
    end
  end
end
