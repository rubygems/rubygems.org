class Mailer < ActionMailer::Base
  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = user
    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t(:confirmation,
           scope: [:clearance, :models, :clearance_mailer],
           default: "Email address confirmation")
  end

  def email_confirmation(user)
    @user = User.find_by_id(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: "Please confirm your email address with rubygems.org"
  end
end
