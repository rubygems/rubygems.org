class AddOwnershipRequestNotifiertoOwnerships < ActiveRecord::Migration[6.1]
  def change
    add_column :ownerships, :ownership_request_notifier, :boolean, default: true, null: false
  end
end
