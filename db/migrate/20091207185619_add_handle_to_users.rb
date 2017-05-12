class AddHandleToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :handle, :string
    add_index :users, :handle
  end

  def self.down
    remove_index :users, :handle
    remove_column :users, :handle
  end
end
