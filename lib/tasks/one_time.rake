namespace :one_time do
  desc "Switch users that have totp_seed as quotes to be nil"
  task totp_seed_nil_fix: :environment do
    User.where(totp_seed: "").update_all(totp_seed: nil)
  end

  desc "Hash mfa recovery codes"
  task hash_recovery_codes: :environment do
    User.where(mfa_hashed_recovery_codes: nil).where.not(mfa_recovery_codes: nil).find_each do |user|
      user.mfa_hashed_recovery_codes = user.mfa_recovery_codes.map { |code| BCrypt::Password.create(code) }
      user.save!(validate: false)
    end
  end

  desc "Remove plain text recovery codes"
  task remove_plain_text_recovery_codes: :environment do
    User.where.not(mfa_recovery_codes: nil).update_all(mfa_recovery_codes: [])
  end
end
