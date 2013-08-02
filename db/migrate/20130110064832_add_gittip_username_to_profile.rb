class AddGittipUsernameToProfile < ActiveRecord::Migration
  def change
    add_column :users, :gittip_username, :string
  end
end
