class AddVerifiedToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :verified, :boolean, default: false, null: false
  end
end
