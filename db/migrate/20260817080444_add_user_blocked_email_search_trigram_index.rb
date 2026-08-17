# frozen_string_literal: true

class AddUserBlockedEmailSearchTrigramIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :users, :blocked_email,
      using: :gin,
      opclass: :gin_trgm_ops,
      where: "blocked_email IS NOT NULL",
      name: :index_users_on_blocked_email_trigram,
      algorithm: :concurrently
  end

  def down
    remove_index :users, name: :index_users_on_blocked_email_trigram, algorithm: :concurrently
  end
end
