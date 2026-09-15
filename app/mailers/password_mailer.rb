# frozen_string_literal: true

class PasswordMailer < ApplicationMailer
  def change_password(user)
    @user = user
    @token = user.issue_password_reset!
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t("clearance.models.clearance_mailer.change_password") do |format|
           format.html
           format.text
         end
  end

  def compromised_password_reset(user)
    @user = user
    @token = user.issue_password_reset!
    @reason = user.compromised_password_reset_reason_for(@token)
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t("password_mailer.compromised_password_reset.subject", host: Gemcutter::HOST_DISPLAY) do |format|
           format.html
           format.text
         end
  end
end
