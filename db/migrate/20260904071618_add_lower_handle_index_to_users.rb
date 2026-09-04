# frozen_string_literal: true

class AddLowerHandleIndexToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :users, "lower(handle)",
      name: :index_users_on_lower_handle,
      algorithm: :concurrently
  end

  def down
    remove_index :users, name: :index_users_on_lower_handle, algorithm: :concurrently
  end
end
