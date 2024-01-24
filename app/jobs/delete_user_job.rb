class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  ASSOCIATIONS = {
    approved_ownership_requests: :destroy,
    closed_ownership_calls: :destroy,
    closed_ownership_requests: :destroy,
    oidc_pending_trusted_publishers: :destroy,
    ownership_calls: :destroy,
    ownership_requests: :destroy,
    ownerships: :destroy,
    subscriptions: :destroy,
    unconfirmed_ownerships: :destroy,
    web_hooks: :destroy,
    webauthn_credentials: :destroy,
    webauthn_verification: :destroy,

    api_keys: nil,
    audits: nil,
    deletions: nil,
    oidc_api_key_roles: nil,
    pushed_versions: nil
  }.freeze

  def perform(user:)
    email = user.email
    return if user.reload.deleted_at?

    begin
      user.transaction do
        user.yank_gems
        user.api_keys.expire_all!
        handle_associations(user)

        user.update!(
          deleted_at: Time.current, email: "deleted+#{user.id}@rubygems.org",
          handle: nil, email_confirmed: false,
          unconfirmed_email: nil, blocked_email: nil,
          api_key: nil, confirmation_token: nil, remember_token: nil,
          twitter_username: nil, webauthn_id: nil, full_name: nil,
          totp_seed: nil, mfa_hashed_recovery_codes: nil,
          mfa_level: :disabled,
          password: SecureRandom.hex(20).encode("UTF-8")
        )
        Mailer.deletion_complete(email).deliver_later
      end
    rescue ActiveRecord::ActiveRecordError => e
      # Catch the exception so we can log it, otherwise using `destroy` would give
      # us no hint as to why the deletion failed.
      Rails.error.report(e, context: { user:, email: }, handled: true)
      Mailer.deletion_failed(email).deliver_later
    end
  end

  def handle_associations(user)
    user.class.reflect_on_all_associations.each do |reflection|
      next if reflection.through_reflection?

      action = ASSOCIATIONS.fetch(reflection.name) do
        raise ActiveRecord::DeleteRestrictionError, reflection.name
      end
      next unless action
      send(:"#{action}_#{reflection.class.name.tr(':', '_')}", user.association(reflection.name), reflection)
    end
  end

  def destroy_ActiveRecord__Reflection__HasManyReflection(association, reflection) # rubocop:disable Naming/MethodName
    # No point in executing the counter update since we're going to destroy the parent anyway
    association.load_target.each { |t| t.destroyed_by_association = reflection }
    association.destroy_all
  end

  def destroy_ActiveRecord__Reflection__HasOneReflection(association, _reflection) # rubocop:disable Naming/MethodName
    association.delete
  end
end
