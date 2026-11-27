# frozen_string_literal: true

class AddUniqueIndexToOIDCIdTokensJti < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_oidc_id_tokens_on_issuer_and_jti"
  ISSUER = "(jwt -> 'claims' ->> 'iss')"
  JTI = "(jwt -> 'claims' ->> 'jti')"
  INDEXED_AS = "(((jwt -> 'claims'::text) ->> 'iss'::text)), (((jwt -> 'claims'::text) ->> 'jti'::text))"

  def up
    # Initialize Strong Migrations' timeouts before allowing concurrent DDL to wait.
    lock_timeout = select_value("SHOW lock_timeout")
    begin
      safety_assured { execute "SET lock_timeout = 0" }

      remove_index :oidc_id_tokens, name: INDEX_NAME, algorithm: :concurrently if index_exists?(:oidc_id_tokens, name: INDEX_NAME, valid: false)

      raise_if_tokens_were_replayed

      add_index :oidc_id_tokens, "#{ISSUER}, #{JTI}",
        unique: true,
        name: INDEX_NAME,
        algorithm: :concurrently,
        if_not_exists: true

      raise_unless_index_enforces_single_use
    ensure
      safety_assured { execute "SET lock_timeout = #{connection.quote(lock_timeout)}" }
    end
  end

  def down
    remove_index :oidc_id_tokens, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end

  private

  def raise_if_tokens_were_replayed
    replayed = select_values(<<~SQL.squish)
      SELECT string_agg(id::text, ', ' ORDER BY id)
      FROM oidc_id_tokens
      WHERE #{ISSUER} IS NOT NULL AND #{JTI} IS NOT NULL
      GROUP BY #{ISSUER}, #{JTI}
      HAVING count(*) > 1
      ORDER BY min(id)
    SQL
    return if replayed.empty?

    raise ActiveRecord::MigrationError, "Cannot build #{INDEX_NAME} over tokens exchanged more than once, oidc_id_tokens ids: #{replayed.join('; ')}"
  end

  def raise_unless_index_enforces_single_use
    index = indexes(:oidc_id_tokens).find { |i| i.name == INDEX_NAME }
    return if index&.valid? && index.unique && index.where.nil? && index.using == :btree && index.columns == INDEXED_AS

    raise ActiveRecord::MigrationError, "#{INDEX_NAME} must be a valid unique btree index on #{ISSUER}, #{JTI} with no WHERE clause"
  end
end
