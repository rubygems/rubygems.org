# frozen_string_literal: true

class AddUserEmailSearchTrigramIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :users, :email,
      using: :gin,
      opclass: :gin_trgm_ops,
      name: :index_users_on_email_trigram,
      algorithm: :concurrently
  end

  def down
    remove_index :users, name: :index_users_on_email_trigram, algorithm: :concurrently
  end
end
