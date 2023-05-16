class RenameMfaSeedToOtpSeed < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :mfa_seed, :otp_seed
  end
end
