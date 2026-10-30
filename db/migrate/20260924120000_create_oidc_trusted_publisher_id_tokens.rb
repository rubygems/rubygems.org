# frozen_string_literal: true

class CreateOIDCTrustedPublisherIdTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_trusted_publisher_id_tokens do |t|
      t.references :api_key, null: true, foreign_key: { on_delete: :nullify }
      t.references :oidc_provider, null: false, foreign_key: true
      t.references :asserted_owner, null: true, foreign_key: { to_table: :users }
      t.string :jti, null: false

      t.timestamps
    end

    add_index :oidc_trusted_publisher_id_tokens, %i[oidc_provider_id jti], unique: true,
      name: "index_oidc_trusted_publisher_id_tokens_on_provider_and_jti"
  end
end
