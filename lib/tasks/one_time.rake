namespace :one_time do
  desc "Populate totp_seed from mfa_seed"
  task populate_totp_seed: :environment do
    User.find_each do |user|
      user.update(totp_seed: user.mfa_seed)
    end
  end
end
