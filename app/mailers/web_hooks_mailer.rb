class WebHooksMailer < ApplicationMailer
  include Roadie::Rails::Automatic

  default from: Clearance.configuration.mailer_sender

  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def webhook_deleted(user_id, rubygem_id, url, failure_count)
    @user = User.find(user_id)
    @rubygem = Rubygem.find(rubygem_id) if rubygem_id
    @url = url
    @failure_count = failure_count

    mail to: @user.email,
         subject: t("mailer.web_hook_deleted.subject") do |format|
           format.html
           format.text
         end
  end

  def webhook_disabled(web_hook)
    @web_hook = web_hook
    @delete_command = "gem install gemcutter && gem webhook#{" #{web_hook.rubygem.name}" unless web_hook.global?} --remove '#{web_hook.url}'"

    mail to: web_hook.user.email,
         subject: t("mailer.web_hook_disabled.subject") do |format|
           format.html
           format.text
         end
  end
end
