namespace :one_time do
  desc "Assign ui_and_gem_signin to webauthn only users"
  task assign_ui_and_gem_signin: :environment do
    User.where(mfa_level: :disabled).where(id: WebauthnCredential.select(:user_id)).update_all(mfa_level: :ui_and_gem_signin)
  end
end
