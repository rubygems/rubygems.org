class RemoveGittip < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :gittip_username
  end
end
