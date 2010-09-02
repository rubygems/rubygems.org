class AddColumnsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :website, :string
    add_column :users, :location, :string
    add_column :users, :bio, :text
  end

  def self.down
    remove_column :users, :bio
    remove_column :users, :location
    remove_column :users, :website
  end
end
