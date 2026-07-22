# frozen_string_literal: true

class CacheExposureMailer < ApplicationMailer
  self.deliver_later_queue_name = :within_24_hours
  self.delivery_job = CacheExposureMailDeliveryJob

  def cache_exposure_notice(user)
    @user = user
    mail to: @user.email,
         reply_to: "support@rubygems.org",
         subject: I18n.t("mailer.cache_exposure_notice.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def cache_exposure_inactive_notice(user)
    @user = user
    mail to: @user.email,
         reply_to: "support@rubygems.org",
         subject: I18n.t("mailer.cache_exposure_inactive_notice.subject", host: Gemcutter::HOST_DISPLAY)
  end
end
