namespace :one_time do
  desc "Switch users that have totp_seed as quotes to be nil"
  task totp_seed_nil_fix: :environment do
    User.where(totp_seed: "").update_all(totp_seed: nil)
  end

  desc "Hash mfa recovery codes"
  task hash_recovery_codes: :environment do
    batch_size = ENV.fetch("BATCH_SIZE", 150).to_i
    User.where(mfa_hashed_recovery_codes: []).where.not(mfa_recovery_codes: []).find_each(batch_size:) do |user|
      user.mfa_hashed_recovery_codes = user.mfa_recovery_codes.map { |code| BCrypt::Password.create(code) }
      user.save!(validate: false)
    end
  end
end
