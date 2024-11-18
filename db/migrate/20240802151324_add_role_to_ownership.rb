class AddRoleToOwnership < ActiveRecord::Migration[7.1]
  def change
    add_column :ownerships, :role, :integer, null: false, default: 70 # Access::OWNER
  end
end
