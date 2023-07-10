class AddHashedMfaRecoveryCodesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :hashed_mfa_recovery_codes, :string, default: [], array: true
  end
end
