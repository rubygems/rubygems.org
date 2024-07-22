class AddMfaToUsers < ActiveRecord::Migration[5.0]
  def change
    change_table(:users, bulk: true) do |t|
      t.string  :mfa_seed
      t.integer :mfa_level, default: 0
      t.string :mfa_recovery_codes, array: true, default: []
      t.datetime :last_otp_at
    end
  end
end
