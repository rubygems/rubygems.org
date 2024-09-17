class AddRoleToMemberships < ActiveRecord::Migration[7.1]
  def change
    add_column :memberships, :role, :integer, null: false, default: 50 # Access::MAINTAINER
  end
end
