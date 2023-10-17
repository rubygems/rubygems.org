class AddOwnershipConfirmation < ActiveRecord::Migration[6.0]
  def change
    add_column :ownerships, :confirmed_at, :datetime  # rubocop:disable Rails/BulkChangeTable
    add_column :ownerships, :token_expires_at, :datetime
    add_column :ownerships, :owner_notifier, :boolean, default: true, null: false
    add_column :ownerships, :authorizer_id, :integer
    add_index :ownerships, %i[user_id rubygem_id], unique: true
  end
end
