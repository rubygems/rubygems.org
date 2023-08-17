class CreateOIDCApiKeyRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_api_key_roles do |t|
      t.references :oidc_provider, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :api_key_permissions, null: false
      t.string :name, null: false
      t.jsonb :access_policy, null: false

      t.timestamps
    end
  end
end
