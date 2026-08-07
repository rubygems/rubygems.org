# frozen_string_literal: true

class AddTrigramIndexesForAvoUserSearch < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    enable_extension "pg_trgm"

    add_index :users, :email,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :index_users_on_email_trigram,
      algorithm: :concurrently
    add_index :users, :blocked_email,
      using: :gin,
      opclass: :gin_trgm_ops,
      where: "blocked_email IS NOT NULL",
      name: :index_users_on_blocked_email_trigram,
      algorithm: :concurrently
    add_index :users, :handle,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :index_users_on_handle_trigram,
      algorithm: :concurrently
  end
end
