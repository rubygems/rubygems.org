class RenameEmailChangedOnUsers < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :users, :email_changed, :email_reset
  end

  def self.down
    rename_column :users, :email_reset, :email_changed
  end
end
