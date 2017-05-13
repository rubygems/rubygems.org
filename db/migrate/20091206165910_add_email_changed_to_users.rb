class AddEmailChangedToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :email_changed, :boolean
  end

  def self.down
    remove_column :users, :email_changed
  end
end
