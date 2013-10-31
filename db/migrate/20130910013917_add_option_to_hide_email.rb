class AddOptionToHideEmail < ActiveRecord::Migration
  def change
    add_column :users, :hide_email, :boolean
  end
end
