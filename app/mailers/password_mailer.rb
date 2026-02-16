# frozen_string_literal: true

class PasswordMailer < ApplicationMailer
  def change_password(user)
    @user = User.find(user["id"])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t("clearance.models.clearance_mailer.change_password") do |format|
           format.html
           format.text
         end
  end

  def compromised_password_reset(user)
    @user = User.find(user["id"])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t("password_mailer.compromised_password_reset.subject", host: Gemcutter::HOST_DISPLAY) do |format|
           format.html
           format.text
         end
  end
end
