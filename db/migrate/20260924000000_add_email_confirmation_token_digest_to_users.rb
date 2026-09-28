# frozen_string_literal: true

class AddEmailConfirmationTokenDigestToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :users, :email_confirmation_token_digest, :string
    add_column :users, :email_confirmation_token_expires_at, :datetime
    add_column :users, :email_confirmation_email, :string
    add_index :users, :email_confirmation_token_digest, unique: true, algorithm: :concurrently
  end
end
