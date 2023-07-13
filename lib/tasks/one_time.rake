namespace :one_time do
  desc "Switch users that have totp_seed as quotes to be nil"
  task totp_seed_nil_fix: :environment do
    User.where(totp_seed: "").update_all(totp_seed: nil)
  end
end