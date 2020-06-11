class Mailer < ApplicationMailer
  include Roadie::Rails::Automatic

  default from: Clearance.configuration.mailer_sender

  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = user
    mail to: @user.unconfirmed_email,
        subject: I18n.t("mailer.confirmation_subject",
          default: "Please confirm your email address with RubyGems.org")
  end

  def email_reset_update(user)
    @user = user
    mail to: @user.email,
         subject: I18n.t("mailer.email_reset_update.subject")
  end

  def email_confirmation(user)
    @user = user
    mail to: @user.email,
        subject: I18n.t("mailer.confirmation_subject",
          default: "Please confirm your email address with RubyGems.org")
  end

  def deletion_complete(email)
    mail to: email,
         subject: I18n.t("mailer.deletion_complete.subject")
  end

  def deletion_failed(email)
    mail to: email,
         subject: I18n.t("mailer.deletion_failed.subject")
  end

  def notifiers_changed(user_id)
    @user = User.find(user_id)
    @ownerships = @user.ownerships.by_indexed_gem_name

    mail to: @user.email,
         subject: I18n.t("mailer.notifiers_changed.subject",
           default: "You changed your RubyGems.org email notification settings")
  end

  def gem_pushed(pushed_by_user_id, version_id, notified_user_id)
    @version = Version.find(version_id)
    notified_user = User.find(notified_user_id)
    @pushed_by_user = User.find(pushed_by_user_id)

    mail to: notified_user.email,
      subject: I18n.t("mailer.gem_pushed.subject", gem: @version.to_title,
                      default: "Gem %{gem} pushed to RubyGems.org")
  end

  def mfa_notification(user_id)
    @user = User.find(user_id)

    mail to: @user.email,
      subject: "Please consider enabling MFA for your account"
  end

  def gem_yanked(yanked_by_user_id, version_id, notified_user_id)
    @version        = Version.find(version_id)
    notified_user   = User.find(notified_user_id)
    @yanked_by_user = User.find(yanked_by_user_id)

    mail to: notified_user.email,
         subject: I18n.t("mailer.gem_yanked.subject", gem: @version.to_title)
  end

  def reset_api_key(user, template_name)
    @user = user
    mail to: @user.email,
         subject: I18n.t("mailer.reset_api_key.subject"),
         template_name: template_name
  end

  def ownership_confirmation(ownership_id)
    @ownership = Ownership.find(ownership_id)
    @user = @ownership.user
    @rubygem = @ownership.rubygem
    mail to: @user.email,
         subject: I18n.t("mailer.ownership_confirmation.subject", gem: @rubygem.name,
                         default: "Please confirm the ownership of %{gem} gem on RubyGems.org")
  end

  def owner_removed(owner_id, user_id, gem_id)
    @user = User.find(user_id)
    @owner = User.find(owner_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: if @owner.id == @user.id
                    I18n.t("mailer.owners_update.subject_self", gem: @rubygem.name, status: "removed")
                  else
                    I18n.t("mailer.owners_update.subject_others", gem: @rubygem.name, status: "removed", owner_handle: @owner.handle)
                  end
  end

  def owner_added(owner_id, user_id, gem_id)
    @user = User.find(user_id)
    @owner = User.find(owner_id)
    @rubygem = Rubygem.find(gem_id)
    mail to: @user.email,
         subject: if @owner.id == @user.id
                    I18n.t("mailer.owners_update.subject_self", gem: @rubygem.name, status: "added")
                  else
                    I18n.t("mailer.owners_update.subject_others", gem: @rubygem.name, status: "added", owner_handle: @owner.handle)
                  end
  end
end
