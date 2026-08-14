# frozen_string_literal: true

class AddPasswordResetTokenDigestToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_table :users, bulk: true do |t|
      t.string :password_reset_token_digest
      t.datetime :password_reset_token_expires_at
    end
    add_index :users, :password_reset_token_digest, unique: true, algorithm: :concurrently
  end
end
