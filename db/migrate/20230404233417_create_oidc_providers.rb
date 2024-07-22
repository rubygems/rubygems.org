class CreateOIDCProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_providers do |t|
      t.text :issuer, index: { unique: true }
      t.jsonb :configuration
      t.jsonb :jwks

      t.timestamps
    end
  end
end
