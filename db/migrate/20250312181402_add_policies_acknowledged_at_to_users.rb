class AddPoliciesAcknowledgedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :policies_acknowledged_at, :datetime
  end
end
