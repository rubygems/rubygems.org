class CreateOIDCIdTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_id_tokens do |t|
      t.references :oidc_api_key_role, null: false, foreign_key: true
      t.jsonb :jwt, null: false
      t.references :oidc_provider, null: false, foreign_key: true
      t.references :api_key, null: true, foreign_key: true

      t.timestamps
    end
  end
end
