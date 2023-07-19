class AddTokenToOIDCApiKeyRole < ActiveRecord::Migration[7.0]
  def change
    add_column :oidc_api_key_roles, :token, :string, null: true, unique: true, limit: 32
    # TODO: remove this once run on the development environment
    OIDC::ApiKeyRole.find_each do |role|
      role.generate_random_token
      role.save!
    end
    change_column :oidc_api_key_roles, :token, :string, null: false, unique: true, limit: 32
    add_index :oidc_api_key_roles, :token, unique: true
  end
end
