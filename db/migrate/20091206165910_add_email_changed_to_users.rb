class AddEmailChangedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_changed, :boolean
  end

  def self.down
    remove_column :users, :email_changed
  end
end
