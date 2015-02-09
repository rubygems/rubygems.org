class RemoveGittip < ActiveRecord::Migration
  def change
    remove_column :users, :gittip_username
  end
end
