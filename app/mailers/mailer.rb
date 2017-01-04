class Mailer < ActionMailer::Base
  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end

  def email_confirmation(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end
end
