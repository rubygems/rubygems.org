class MailerPreview < ActionMailer::Preview
  def email_reset
    Mailer.email_reset(User.first)
  end

  def email_reset_update
    Mailer.email_reset_update(User.last)
  end

  def email_confirmation
    Mailer.email_confirmation(User.last)
  end

  def change_password
    ClearanceMailer.change_password(User.last)
  end

  def deletion_complete
    Mailer.deletion_complete(User.last)
  end

  def deletion_failed
    Mailer.deletion_failed(User.last)
  end

  def notifiers_changed
    ownership = Ownership.where.not(user: nil).last
    Mailer.notifiers_changed(ownership.user_id)
  end

  def gem_pushed
    ownership = Ownership.where.not(user: nil).where(push_notifier: true).last
    Mailer.gem_pushed(ownership.user_id, ownership.rubygem.versions.last.id, ownership.user_id)
  end

  def mfa_notification
    Mailer.mfa_notification(User.last.id)
  end

  def mfa_recommendation_announcement
    Mailer.mfa_recommendation_announcement(User.last.id)
  end

  def mfa_required_soon_announcement
    Mailer.mfa_required_soon_announcement(User.last.id)
  end

  def mfa_required_popular_gems_announcement
    Mailer.mfa_required_popular_gems_announcement(User.last.id)
  end

  def gem_yanked
    ownership = Ownership.where.not(user: nil).last
    Mailer.gem_yanked(ownership.user.id, ownership.rubygem.versions.last.id, ownership.user.id)
  end

  def public_gem_reset_api_key
    user = User.last
    Mailer.reset_api_key(user, "public_gem_reset_api_key")
  end

  def honeycomb_reset_api_key
    user = User.last
    Mailer.reset_api_key(user, "honeycomb_reset_api_key")
  end

  def ownership_confirmation
    OwnersMailer.ownership_confirmation(Ownership.last)
  end

  def owner_removed
    gem = Rubygem.order(updated_at: :desc).first
    user = User.last
    authorizer = gem.owners.first
    OwnersMailer.owner_removed(user.id, authorizer.id, gem.id)
  end

  def owner_added
    gem = Rubygem.order(updated_at: :desc).last
    owner = Ownership.last.user
    authorizer = Ownership.last.authorizer
    user = User.last
    OwnersMailer.owner_added(user.id, owner.id, authorizer.id, gem.id)
  end

  def api_key_created
    api_key = ApiKey.last
    Mailer.api_key_created(api_key.id)
  end

  def api_key_created_oidc_api_key_role
    api_key = OIDC::IdToken.last.api_key
    Mailer.api_key_created(api_key.id)
  end

  def api_key_revoked
    api_key = ApiKey.last
    Mailer.api_key_revoked(api_key.user.id, api_key.name, api_key.enabled_scopes.join(", "), "https://example.com")
  end

  def new_ownership_requests
    gem = Rubygem.order(updated_at: :desc).last
    user = gem.owners.last
    OwnersMailer.new_ownership_requests(gem.id, user.id)
  end

  def ownership_request_closed
    ownership_request = OwnershipRequest.last
    OwnersMailer.ownership_request_closed(ownership_request.id)
  end

  def ownership_request_approved
    ownership_request = OwnershipRequest.last
    OwnersMailer.ownership_request_approved(ownership_request.id)
  end

  def webhook_deleted_global
    user = User.last
    url = "https://example.com/webhook"
    failure_count = 9999

    WebHooksMailer.webhook_deleted(user.id, nil, url, failure_count)
  end

  def webhook_deleted_single_gem
    gem = Rubygem.order(updated_at: :desc).last
    user = gem.owners.last
    url = "https://example.com/webhook"
    failure_count = 9999

    WebHooksMailer.webhook_deleted(user.id, gem.id, url, failure_count)
  end

  def webhook_disabled_global
    web_hook = WebHook.new(
      user: User.last,
      last_failure: 2.minutes.ago,
      last_success: 1.week.ago,
      successes_since_last_failure: 0,
      failures_since_last_success: 10,
      failure_count: 200,
      url: "https://example.com/webhook",
      disabled_reason: WebHook::TOO_MANY_FAILURES_DISABLED_REASON
    )

    WebHooksMailer.webhook_disabled(web_hook)
  end

  def webhook_disabled_single_gem
    rubygem = Rubygem.order(updated_at: :desc).last
    user = rubygem.owners.last
    web_hook = WebHook.new(
      rubygem:,
      user:,
      last_failure: 2.minutes.ago,
      last_success: 1.week.ago,
      successes_since_last_failure: 0,
      failures_since_last_success: 10,
      failure_count: 200,
      url: "https://example.com/webhook",
      disabled_reason: WebHook::TOO_MANY_FAILURES_DISABLED_REASON
    )

    WebHooksMailer.webhook_disabled(web_hook)
  end

  def webauthn_credential_created
    webauthn_credential = WebauthnCredential.last

    unless webauthn_credential
      user_with_yubikey = User.create_with(
        handle: "gem-user-with-yubikey",
        password: "super-secret-password",
        email_confirmed: true
      ).find_or_create_by!(email: "gem-user-with-yubikey@example.com")

      webauthn_credential = user_with_yubikey.webauthn_credentials.create_with(
        external_id: "external-id",
        public_key: "public-key",
        sign_count: 1
      ).find_or_create_by!(nickname: "Fake Yubikey")
    end

    Mailer.webauthn_credential_created(webauthn_credential.id)
  end

  def webauthn_credential_removed
    user_id = User.last.id
    webauthn_credential_nickname = "Fake Yubikey"

    Mailer.webauthn_credential_removed(user_id, webauthn_credential_nickname, Time.now.utc)
  end

  def totp_enabled
    user_id = User.last.id

    Mailer.totp_enabled(user_id, Time.now.utc)
  end

  def totp_disabled
    user_id = User.last.id

    Mailer.totp_disabled(user_id, Time.now.utc)
  end
end
