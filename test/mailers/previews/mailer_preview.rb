class MailerPreview < ActionMailer::Preview
  def email_reset
    Mailer.email_reset(User.last)
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
    OwnersMailer.ownership_confirmation(Ownership.last.id)
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
end
