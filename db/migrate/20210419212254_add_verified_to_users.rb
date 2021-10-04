class AddVerifiedToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :verified, :boolean, default: false, null: false
  end
end
