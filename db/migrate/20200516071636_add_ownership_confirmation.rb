class AddOwnershipConfirmation < ActiveRecord::Migration[6.0]
  def change
    add_column :ownerships, :confirmed_at, :datetime
    add_column :ownerships, :token_expires_at, :datetime
    add_column :ownerships, :owner_notifier, :boolean, default: true, null: false
    add_column :ownerships, :authorizer_id, :integer
  end
end
