# frozen_string_literal: true

class AddPasswordResetTokenDigestToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Strong Migrations cannot inspect change_table blocks.
    add_column :users, :password_reset_token_digest, :string
    add_column :users, :password_reset_token_expires_at, :datetime
    add_index :users, :password_reset_token_digest, unique: true, algorithm: :concurrently
  end
end
