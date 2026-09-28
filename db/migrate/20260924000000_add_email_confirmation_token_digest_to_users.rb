# frozen_string_literal: true

class AddEmailConfirmationTokenDigestToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Strong Migrations cannot inspect change_table blocks.
    # rubocop:disable Rails/BulkChangeTable
    add_column :users, :email_confirmation_token_digest, :string
    add_column :users, :email_confirmation_token_expires_at, :datetime
    add_column :users, :email_confirmation_email, :string
    # rubocop:enable Rails/BulkChangeTable
    add_index :users, :email_confirmation_token_digest, unique: true, algorithm: :concurrently
  end
end
