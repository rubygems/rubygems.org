class AddTokenToOIDCApiKeyRole < ActiveRecord::Migration[7.0]
  def change
    add_column :oidc_api_key_roles, :token, :string, null: false, unique: true, limit: 32
    add_index :oidc_api_key_roles, :token, unique: true
  end
end
