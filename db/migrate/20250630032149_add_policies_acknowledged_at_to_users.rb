class AddPoliciesAcknowledgedAtToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :policies_acknowledged_at, :datetime
    add_index :users, :id, where: "policies_acknowledged_at IS NULL", name: :index_users_on_policies_not_acknowledged, algorithm: :concurrently
  end
end
