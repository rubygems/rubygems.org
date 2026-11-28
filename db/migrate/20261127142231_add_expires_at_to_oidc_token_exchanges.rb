# frozen_string_literal: true

class AddExpiresAtToOIDCTokenExchanges < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = :index_oidc_token_exchanges_on_expires_at

  def up
    # The exchanged token's own exp. Null on rows written before this column, which are never pruned.
    add_column :oidc_token_exchanges, :expires_at, :datetime, if_not_exists: true

    # Let the concurrent build wait past Strong Migrations' lock timeout, as the other index migrations do.
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      if index_exists?(:oidc_token_exchanges, name: INDEX_NAME, valid: false)
        remove_index :oidc_token_exchanges, name: INDEX_NAME, algorithm: :concurrently
      end

      add_index :oidc_token_exchanges, :expires_at, name: INDEX_NAME, algorithm: :concurrently, if_not_exists: true
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end

  def down
    remove_index :oidc_token_exchanges, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
    remove_column :oidc_token_exchanges, :expires_at, if_exists: true
  end
end
