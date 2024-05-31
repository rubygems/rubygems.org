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
end
