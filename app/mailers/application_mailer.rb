# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include SemanticLogger::Loggable
  include Roadie::Rails::Automatic

  default from: Gemcutter::MAIL_SENDER

  layout "mailer"

  around_action :use_default_locale
  after_deliver :record_delivery

  def record_delivery
    message.to_addrs&.each do |address|
      user = User.find_by_email(address)
      next unless user

      user.record_event!(Events::UserEvent::EMAIL_SENT,
        to: address,
        from: message.from_addrs&.first,
        subject: message.subject,
        message_id: message.message_id,
        action: action_name,
        mailer: mailer_name)
    end
  end

  private

  def use_default_locale(&block)
    I18n.with_locale(I18n.default_locale, &block)
  end
end
