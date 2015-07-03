class Mailer < ActionMailer::Base
  default_url_options[:host] = Gemcutter::HOST

  def email_reset(user)
    @user = user
    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t(:confirmation,
                            scope: [:clearance, :models, :clearance_mailer],
                            default: "Email address confirmation")
  end
end
