class AddLastUsedOnToWebauthnCredentials < ActiveRecord::Migration[5.2]
  def change
    add_column :webauthn_credentials, :last_used_on, :datetime
  end
end
