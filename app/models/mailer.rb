class Mailer < ActionMailer::Base
  default_url_options[:host] = HOST

  def email_reset(user)
    from       ClearanceMailer::DO_NOT_REPLY
    recipients user.email
    subject    I18n.t(:confirmation,
                      :scope   => [:clearance, :models, :clearance_mailer],
                      :default => "Email address confirmation")
    body      :user => user
  end
end
