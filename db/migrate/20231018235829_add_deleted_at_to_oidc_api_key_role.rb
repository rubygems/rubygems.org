class AddDeletedAtToOIDCApiKeyRole < ActiveRecord::Migration[7.0]
  def change
    add_column :oidc_api_key_roles, :deleted_at, :datetime
  end
end
