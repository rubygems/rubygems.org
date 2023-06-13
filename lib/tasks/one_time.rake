namespace :one_time do
  desc "Populate totp_seed from mfa_seed"
  task populate_totp_seed: :environment do
    User.where.not(mfa_seed: nil).update_all("totp_seed = mfa_seed")
  end

  desc "Assign ui_and_gem_signin to webauthn only users"
  task assign_ui_and_gem_signin: :environment do
    User.where(mfa_level: :disabled).where(id: WebauthnCredential.select(:user_id)).update_all(mfa_level: :ui_and_gem_signin)
  end
end
