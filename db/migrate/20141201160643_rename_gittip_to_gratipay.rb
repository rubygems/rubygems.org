class RenameGittipToGratipay < ActiveRecord::Migration
  def change
    rename_column :users, :gittip_username, :gratipay_username
  end
end
