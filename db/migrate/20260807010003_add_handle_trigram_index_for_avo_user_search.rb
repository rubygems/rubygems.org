# frozen_string_literal: true

class AddHandleTrigramIndexForAvoUserSearch < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_users_on_handle_trigram"

  disable_ddl_transaction!

  def up
    remove_invalid_index
    return if index_exists?(:users, :handle, name: INDEX_NAME)

    add_index :users, :handle,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: INDEX_NAME,
      algorithm: :concurrently
  end

  def down
    remove_index :users, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end

  private

  def remove_invalid_index
    return unless invalid_index?

    safety_assured do
      execute "DROP INDEX CONCURRENTLY #{connection.quote_table_name(INDEX_NAME)}"
    end
  end

  def invalid_index?
    select_value(<<~SQL.squish).present?
      SELECT 1
      FROM pg_class indexes
      INNER JOIN pg_index ON pg_index.indexrelid = indexes.oid
      WHERE indexes.relname = #{connection.quote(INDEX_NAME)}
        AND pg_table_is_visible(indexes.oid)
        AND NOT pg_index.indisvalid
    SQL
  end
end
