class AddTwitterHandleToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :twitter_username, :string
  end
end
