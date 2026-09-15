# frozen_string_literal: true

class AddUserHandleSearchTrigramIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :users, :handle,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :index_users_on_handle_trigram,
      algorithm: :concurrently
  end

  def down
    remove_index :users, name: :index_users_on_handle_trigram, algorithm: :concurrently
  end
end
