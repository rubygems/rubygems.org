namespace :one_time do
  desc "Populate otp_seed from mfa_seed"
  task populate_otp_seed: :environment do
    User.find_each do |user|
      user.update(otp_seed: user.mfa_seed)
    end
  end
end
