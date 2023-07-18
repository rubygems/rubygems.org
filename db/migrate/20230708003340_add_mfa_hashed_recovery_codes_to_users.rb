class AddMfaHashedRecoveryCodesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :mfa_hashed_recovery_codes, :string, default: [], array: true
  end
end
