class AddGittipUsernameToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :gittip_username, :string
  end
end
