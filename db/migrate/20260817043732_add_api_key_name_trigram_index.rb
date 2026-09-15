# frozen_string_literal: true

class AddApiKeyNameTrigramIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    enable_extension "pg_trgm"
    add_index :api_keys, :name,
      using: :gin,
      opclass: :gin_trgm_ops,
      where: "owner_type = 'User'",
      name: :index_api_keys_on_name_trigram_for_users,
      algorithm: :concurrently
  end

  def down
    remove_index :api_keys,
      name: :index_api_keys_on_name_trigram_for_users,
      algorithm: :concurrently
  end
end
