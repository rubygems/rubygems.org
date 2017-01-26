class AddTwitterHandleToUsers < ActiveRecord::Migration
  def change
    add_column :users, :twitter_username, :string
  end
end
