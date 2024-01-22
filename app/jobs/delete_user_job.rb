class DeleteUserJob < ApplicationJob
  queue_as :default
  queue_with_priority PRIORITIES.fetch(:profile_deletion)

  def perform(user:)
    email = user.email
    return if user.reload.deleted_at?

    begin
      user.transaction do
        user.yank_gems
        user.api_keys.expire_all!
        user.class.reflect_on_all_associations.each do |association|
          next if association.name == :api_keys
          case association.options[:dependent]
          when :destroy, :destroy_async
            user.association(association.name).handle_dependency
          end
        end
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
end
