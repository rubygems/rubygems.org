class Mailer < ApplicationMailer
  def email_reset(user)
    @user = user
    mail to: @user.unconfirmed_email,
        subject: I18n.t("mailer.confirmation_subject", host: Gemcutter::HOST_DISPLAY,
        default: "Please confirm your email address with #{Gemcutter::HOST_DISPLAY}") do |format|
          format.html
          format.text
        end
  end

  def email_reset_update(user)
    @user = user
    mail to: @user.email,
         subject: I18n.t("mailer.email_reset_update.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def email_confirmation(user)
    @user = user

    if @user.confirmation_token
      mail to: @user.email,
           subject: I18n.t("mailer.confirmation_subject", host: Gemcutter::HOST_DISPLAY,
           default: "Please confirm your email address with #{Gemcutter::HOST_DISPLAY}") do |format|
             format.html
             format.text
           end
    else
      Rails.logger.info("[mailer:email_confirmation] confirmation token not found. skipping sending mail for #{@user.handle}")
    end
  end

  def admin_manual(user, subject, body)
    @user = user
    @body = body
    @sub_title = subject
    mail to: @user.email,
         subject: subject do |format|
           format.html
           format.text
         end
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

  def gem_pushed(pushed_by, version_id, notified_user_id)
    @version = Version.find(version_id)
    notified_user = User.find(notified_user_id)
    @pushed_by_user = pushed_by

    mail to: notified_user.email,
      subject: I18n.t("mailer.gem_pushed.subject", gem: @version.to_title, host: Gemcutter::HOST_DISPLAY,
                      default: "Gem %{gem} pushed to RubyGems.org")
  end

  def gem_trusted_publisher_added(rubygem_trusted_publisher, created_by_user, notified_user)
    @rubygem_trusted_publisher = rubygem_trusted_publisher
    @created_by_user = created_by_user
    @notified_user = notified_user

    mail to: notified_user.email,
      subject: I18n.t("mailer.gem_trusted_publisher_added.subject",
        gem: @rubygem_trusted_publisher.rubygem.name,
        host: Gemcutter::HOST_DISPLAY,
        default: "Trusted publisher added to %{gem} on RubyGems.org")
  end

  def mfa_notification(user_id)
    @user = User.find(user_id)

    mail to: @user.email,
      subject: "Please consider enabling multi-factor authentication for your account"
  end

  def mfa_recommendation_announcement(user_id)
    @user = User.find(user_id)

    mail to: @user.email,
      subject: "Please enable multi-factor authentication on your RubyGems account"
  end

  def mfa_required_soon_announcement(user_id)
    @user = User.find(user_id)
    @heading = mfa_required_soon_heading(@user.mfa_level)

    mail to: @user.email,
      subject: mfa_required_soon_subject(@user.mfa_level)
  end

  def mfa_required_popular_gems_announcement(user_id)
    @user = User.find(user_id)
    @heading = mfa_required_popular_gems_heading(@user.mfa_level)

    mail to: @user.email,
      subject: mfa_required_popular_gems_subject(@user.mfa_level)
  end

  def webauthn_credential_created(webauthn_credential_id)
    @webauthn_credential = WebauthnCredential.find(webauthn_credential_id)

    mail to: @webauthn_credential.user.email,
      subject: I18n.t("mailer.webauthn_credential_created.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def webauthn_credential_removed(user_id, nickname, deleted_at)
    @user = User.find(user_id)
    @nickname = nickname
    @deleted_at = deleted_at

    mail to: @user.email,
      subject: I18n.t("mailer.webauthn_credential_removed.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def totp_enabled(user_id, enabled_at)
    @user = User.find(user_id)
    @enabled_at = enabled_at

    mail to: @user.email,
      subject: I18n.t("mailer.totp_enabled.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def totp_disabled(user_id, disabled_at)
    @user = User.find(user_id)
    @disabled_at = disabled_at

    mail to: @user.email,
      subject: I18n.t("mailer.totp_disabled.subject", host: Gemcutter::HOST_DISPLAY)
  end

  def gem_yanked(yanked_by_user_id, version_id, notified_user_id)
    @version        = Version.find(version_id)
    notified_user   = User.find(notified_user_id)
    @yanked_by_user = User.find(yanked_by_user_id)

    mail to: notified_user.email,
         subject: I18n.t("mailer.gem_yanked.subject", gem: @version.to_title, host: Gemcutter::HOST_DISPLAY)
  end

  def reset_api_key(user, template_name)
    @user = user
    mail to: @user.email,
         subject: I18n.t("mailer.reset_api_key.subject", host: Gemcutter::HOST_DISPLAY),
         template_name: template_name
  end

  def api_key_created(api_key_id)
    @api_key = ApiKey.find(api_key_id)

    mail to: @api_key.user.email,
      subject: I18n.t("mail.api_key_created.subject", default: "New API key created for rubygems.org")
  end

  def api_key_revoked(user_id, api_key_name, enabled_scopes, commit_url)
    @commit_url = commit_url
    @user = User.find(user_id)
    @api_key_name = api_key_name
    @enabled_scopes = enabled_scopes
    mail to: @user.email,
      subject: I18n.t("mail.api_key_revoked.subject", default: "One of your API keys was revoked on rubygems.org")
  end
end
