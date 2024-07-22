class RemoveMfaRecoveryCodesFromUser < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :mfa_recovery_codes, :string, default: [], array: true
  end
end
