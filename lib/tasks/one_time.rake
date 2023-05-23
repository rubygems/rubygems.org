namespace :one_time do
  desc "Populate totp_seed from mfa_seed"
  task populate_totp_seed: :environment do
    User.where.not(mfa_seed: nil).update_all('totp_seed = mfa_seed')
  end
end
