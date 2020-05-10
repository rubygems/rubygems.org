class ChangeCredentialsToWebauthnCredentials < ActiveRecord::Migration[5.2]
  def change
    rename_table :credentials, :webauthn_credentials
    add_column :webauthn_credentials, :nickname, :string, null: false
    add_column :webauthn_credentials, :sign_count, :integer, null: false, default: 0
  end
end
