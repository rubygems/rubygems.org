# frozen_string_literal: true

class CreateOIDCTokenExchanges < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_token_exchanges do |t|
      t.references :oidc_provider, null: false, foreign_key: true, index: false
      t.string :jti, null: false

      t.timestamps
    end

    add_index :oidc_token_exchanges, %i[oidc_provider_id jti], unique: true
  end
end
