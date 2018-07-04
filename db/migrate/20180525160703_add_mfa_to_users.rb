class AddMfaToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :mfa_seed, :string
    add_column :users, :mfa_level, :integer, default: 0
    add_column :users, :mfa_recovery_codes, :string, array: true, default: []
    add_column :users, :last_otp_at, :datetime
  end
end
