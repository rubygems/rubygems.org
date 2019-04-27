class AddMailFailsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :mail_fails, :integer, default: 0
  end
end
