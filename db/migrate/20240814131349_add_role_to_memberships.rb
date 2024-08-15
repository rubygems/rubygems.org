class AddRoleToMemberships < ActiveRecord::Migration[7.1]
  def change
    add_column :memberships, :role, :integer, default: 0
  end
end
