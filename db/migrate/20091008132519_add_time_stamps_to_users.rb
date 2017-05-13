class AddTimeStampsToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :created_at, :datetime
    add_column :users, :updated_at, :datetime
  end

  def self.down
    remove_column :users, :created_at
    remove_column :users, :updated_at
  end
end
